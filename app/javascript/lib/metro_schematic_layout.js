const DEFAULTS = {
  horizontalGap: 280,
  trackGap: 86,
  marginX: 120,
  marginY: 100
}

export function calculateMetroSchematicLayout({ nodes, edges, rootId, options = {} }) {
  const settings = { ...DEFAULTS, ...options }
  const nodesById = new Map(nodes.map((node) => [node.id, node]))
  const validEdges = edges.filter((edge) => nodesById.has(edge.source) && nodesById.has(edge.target))
  const outgoing = mapLists(nodesById.keys())
  const incoming = mapLists(nodesById.keys())

  validEdges.forEach((edge) => {
    outgoing.get(edge.source).push(edge)
    incoming.get(edge.target).push(edge)
  })
  outgoing.forEach((list) => list.sort((a, b) => compareEdges(a, b, nodesById)))

  const depthById = calculateDepths(rootId, nodesById, outgoing)
  const supportParentById = chooseSupportParents(rootId, nodesById, incoming, depthById)
  const childrenById = mapLists(nodesById.keys())
  supportParentById.forEach((parentId, childId) => childrenById.get(parentId)?.push(childId))
  childrenById.forEach((children) => children.sort((a, b) => compareNodes(nodesById.get(a), nodesById.get(b))))

  const yById = assignTracks(rootId, nodesById, childrenById, settings)
  const positions = new Map()
  nodesById.forEach((_node, id) => {
    positions.set(id, {
      x: settings.marginX + depthById.get(id) * settings.horizontalGap,
      y: yById.get(id),
      depth: depthById.get(id)
    })
  })

  const paths = new Map()
  validEdges.forEach((edge) => {
    paths.set(edge.id, routeMetroConnection(positions.get(edge.source), positions.get(edge.target)))
  })

  const maxX = Math.max(settings.marginX, ...Array.from(positions.values(), (position) => position.x))
  const maxY = Math.max(settings.marginY, ...Array.from(positions.values(), (position) => position.y))
  return {
    positions,
    paths,
    supportParentById,
    bounds: {
      x: 0,
      y: 0,
      width: Math.max(900, maxX + settings.marginX),
      height: Math.max(560, maxY + settings.marginY)
    }
  }
}

function mapLists(ids) {
  return new Map(Array.from(ids, (id) => [id, []]))
}

function calculateDepths(rootId, nodesById, outgoing) {
  const depths = new Map()
  const queue = []
  if (nodesById.has(rootId)) {
    depths.set(rootId, 0)
    queue.push(rootId)
  }

  while (queue.length) {
    const sourceId = queue.shift()
    const nextDepth = depths.get(sourceId) + 1
    outgoing.get(sourceId)?.forEach((edge) => {
      if (depths.has(edge.target) && depths.get(edge.target) <= nextDepth) return
      depths.set(edge.target, nextDepth)
      queue.push(edge.target)
    })
  }

  let disconnectedDepth = Math.max(0, ...depths.values()) + 1
  nodesById.forEach((_node, id) => {
    if (depths.has(id)) return
    depths.set(id, disconnectedDepth)
    disconnectedDepth += 1
  })
  return depths
}

function chooseSupportParents(rootId, nodesById, incoming, depthById) {
  const parents = new Map()
  nodesById.forEach((_node, id) => {
    if (id === rootId) return
    const candidates = (incoming.get(id) || [])
      .filter((edge) => depthById.get(edge.source) < depthById.get(id))
      .sort((a, b) => {
        const kindDifference = edgePriority(a) - edgePriority(b)
        if (kindDifference) return kindDifference
        const depthDifference = depthById.get(b.source) - depthById.get(a.source)
        return depthDifference || compareNodes(nodesById.get(a.source), nodesById.get(b.source))
      })
    if (candidates.length) parents.set(id, candidates[0].source)
  })
  return parents
}

function assignTracks(rootId, nodesById, childrenById, settings) {
  const yById = new Map()
  const visited = new Set()
  let nextTrack = 0

  const visit = (id) => {
    if (visited.has(id)) return yById.get(id)
    visited.add(id)
    const children = (childrenById.get(id) || []).filter((childId) => !visited.has(childId))
    if (!children.length) {
      const y = settings.marginY + nextTrack * settings.trackGap
      nextTrack += 1
      yById.set(id, y)
      return y
    }

    const childYs = children.map(visit).filter(Number.isFinite)
    const y = childYs.length ? (childYs[0] + childYs[childYs.length - 1]) / 2 : settings.marginY + nextTrack++ * settings.trackGap
    yById.set(id, y)
    return y
  }

  if (nodesById.has(rootId)) visit(rootId)
  Array.from(nodesById.values()).sort(compareNodes).forEach((node) => {
    if (!visited.has(node.id)) visit(node.id)
  })
  return yById
}

export function routeMetroConnection(source, target) {
  if (!source || !target) return []
  const dx = target.x - source.x
  const dy = target.y - source.y
  if (dx === 0 || dy === 0 || Math.abs(dx) === Math.abs(dy)) return compactPoints([source, target])

  const horizontalDistance = Math.abs(dx)
  const verticalDistance = Math.abs(dy)
  if (horizontalDistance >= verticalDistance) {
    return compactPoints([
      source,
      { x: target.x - Math.sign(dx) * verticalDistance, y: source.y },
      target
    ])
  }

  return compactPoints([
    source,
    { x: source.x, y: target.y - Math.sign(dy) * horizontalDistance },
    target
  ])
}

export function routeMetroNetwork(positions, edges, options = {}) {
  const settings = {
    laneGap: 34,
    stationClearance: 30,
    bendPenalty: 28,
    crossingPenalty: 1800,
    overlapPenalty: 9000,
    proximityPenalty: 700,
    stationPenalty: 5000,
    ...options
  }
  const routed = new Map()
  const occupiedSegments = []
  const orderedEdges = [...edges].sort((left, right) => {
    const kind = edgePriority(left) - edgePriority(right)
    if (kind) return kind
    const leftLength = directDistance(positions.get(left.source), positions.get(left.target))
    const rightLength = directDistance(positions.get(right.source), positions.get(right.target))
    return rightLength - leftLength || left.id.localeCompare(right.id)
  })

  orderedEdges.forEach((edge) => {
    const source = positions.get(edge.source)
    const target = positions.get(edge.target)
    if (!source || !target) return

    const sourceOffset = endpointOffset(edge, "source", edges, positions, settings.laneGap)
    const targetOffset = endpointOffset(edge, "target", edges, positions, settings.laneGap)
    const ports = connectionPorts(source, target, sourceOffset, targetOffset)
    const candidates = candidateRoutes(ports.source, ports.target, settings.laneGap)
      .map((middle) => compactPolyline([source, ports.source, ...middle.slice(1, -1), ports.target, target]))
    const otherStations = Array.from(positions.entries())
      .filter(([id]) => id !== edge.source && id !== edge.target)
      .map(([, position]) => position)
    const best = candidates.reduce((winner, candidate) => {
      const score = routeScore(candidate, occupiedSegments, otherStations, settings)
      return !winner || score < winner.score ? { path: candidate, score } : winner
    }, null)?.path || routeMetroConnection(source, target)

    routed.set(edge.id, best)
    occupiedSegments.push(...segmentsFor(best).map((segment) => ({ ...segment, edgeId: edge.id })))
  })

  return routed
}

function endpointOffset(edge, endpoint, edges, positions, laneGap) {
  const opposite = endpoint === "source" ? "target" : "source"
  const peers = edges
    .filter((candidate) => candidate[endpoint] === edge[endpoint])
    .sort((left, right) => {
      const leftPosition = positions.get(left[opposite])
      const rightPosition = positions.get(right[opposite])
      return (leftPosition?.y || 0) - (rightPosition?.y || 0) ||
        (leftPosition?.x || 0) - (rightPosition?.x || 0) ||
        left.id.localeCompare(right.id)
    })
  if (peers.length < 2) return 0
  return (peers.findIndex((candidate) => candidate.id === edge.id) - (peers.length - 1) / 2) * Math.min(14, laneGap / 2)
}

function connectionPorts(source, target, sourceOffset, targetOffset) {
  const direction = unitDirection(source, target)
  const distance = Math.min(34, directDistance(source, target) / 4)
  return {
    source: {
      x: source.x + direction.x * distance - direction.y * sourceOffset,
      y: source.y + direction.y * distance + direction.x * sourceOffset
    },
    target: {
      x: target.x - direction.x * distance - direction.y * targetOffset,
      y: target.y - direction.y * distance + direction.x * targetOffset
    }
  }
}

function candidateRoutes(source, target, laneGap) {
  const midX = (source.x + target.x) / 2
  const midY = (source.y + target.y) / 2
  const signX = Math.sign(target.x - source.x) || 1
  const signY = Math.sign(target.y - source.y) || 1
  const xLanes = uniqueNumbers([
    midX,
    source.x + signX * 72,
    target.x - signX * 72,
    ...[-3, -2, -1, 1, 2, 3].map((offset) => midX + offset * laneGap)
  ])
  const yLanes = uniqueNumbers([
    midY,
    source.y + signY * 72,
    target.y - signY * 72,
    ...[-3, -2, -1, 1, 2, 3].map((offset) => midY + offset * laneGap)
  ])
  const candidates = [routeMetroConnection(source, target)]

  xLanes.forEach((x) => candidates.push(compactPolyline([
    source,
    { x, y: source.y },
    { x, y: target.y },
    target
  ])))
  yLanes.forEach((y) => candidates.push(compactPolyline([
    source,
    { x: source.x, y },
    { x: target.x, y },
    target
  ])))

  const xPairs = [
    [source.x + signX * 72, target.x - signX * 72],
    [midX - laneGap, midX + laneGap],
    [midX + laneGap, midX - laneGap]
  ]
  const crossingLanes = [midY - laneGap, midY, midY + laneGap]
  xPairs.forEach(([x1, x2]) => {
    crossingLanes.forEach((y) => candidates.push(compactPolyline([
        source,
        { x: x1, y: source.y },
        { x: x1, y },
        { x: x2, y },
        { x: x2, y: target.y },
        target
      ])))
  })

  return uniqueRoutes(candidates)
}

function routeScore(path, occupiedSegments, stations, settings) {
  const segments = segmentsFor(path)
  let score = segments.reduce((total, segment) => total + segment.length, 0)
  score += Math.max(0, path.length - 2) * settings.bendPenalty

  segments.forEach((segment) => {
    occupiedSegments.forEach((occupied) => {
      if (!segmentsMayInteract(segment, occupied, settings.laneGap)) return
      if (segmentsOverlap(segment, occupied)) score += settings.overlapPenalty
      else if (segmentsCross(segment, occupied)) score += settings.crossingPenalty
      else if (parallelDistance(segment, occupied) < settings.laneGap * 0.7) score += settings.proximityPenalty
    })
    stations.forEach((station) => {
      if (!pointNearSegmentBounds(station, segment, settings.stationClearance)) return
      if (pointSegmentDistance(station, segment.a, segment.b) < settings.stationClearance) score += settings.stationPenalty
    })
  })
  return score
}

function segmentsMayInteract(left, right, margin) {
  return Math.max(Math.min(left.a.x, left.b.x), Math.min(right.a.x, right.b.x)) <=
      Math.min(Math.max(left.a.x, left.b.x), Math.max(right.a.x, right.b.x)) + margin &&
    Math.max(Math.min(left.a.y, left.b.y), Math.min(right.a.y, right.b.y)) <=
      Math.min(Math.max(left.a.y, left.b.y), Math.max(right.a.y, right.b.y)) + margin
}

function pointNearSegmentBounds(point, segment, margin) {
  return point.x >= Math.min(segment.a.x, segment.b.x) - margin &&
    point.x <= Math.max(segment.a.x, segment.b.x) + margin &&
    point.y >= Math.min(segment.a.y, segment.b.y) - margin &&
    point.y <= Math.max(segment.a.y, segment.b.y) + margin
}

function segmentsFor(path) {
  return path.slice(1).map((point, index) => {
    const a = path[index]
    return { a, b: point, length: directDistance(a, point) }
  })
}

function segmentsOverlap(left, right) {
  const leftHorizontal = nearlyEqual(left.a.y, left.b.y)
  const rightHorizontal = nearlyEqual(right.a.y, right.b.y)
  if (leftHorizontal && rightHorizontal && nearlyEqual(left.a.y, right.a.y)) {
    return rangesOverlap(left.a.x, left.b.x, right.a.x, right.b.x) > 4
  }
  const leftVertical = nearlyEqual(left.a.x, left.b.x)
  const rightVertical = nearlyEqual(right.a.x, right.b.x)
  if (leftVertical && rightVertical && nearlyEqual(left.a.x, right.a.x)) {
    return rangesOverlap(left.a.y, left.b.y, right.a.y, right.b.y) > 4
  }
  return false
}

function segmentsCross(left, right) {
  const denominator = (left.b.x - left.a.x) * (right.b.y - right.a.y) -
    (left.b.y - left.a.y) * (right.b.x - right.a.x)
  if (Math.abs(denominator) < 0.001) return false
  const ua = ((right.a.x - left.a.x) * (right.b.y - right.a.y) -
    (right.a.y - left.a.y) * (right.b.x - right.a.x)) / denominator
  const ub = ((right.a.x - left.a.x) * (left.b.y - left.a.y) -
    (right.a.y - left.a.y) * (left.b.x - left.a.x)) / denominator
  return ua > 0.03 && ua < 0.97 && ub > 0.03 && ub < 0.97
}

function parallelDistance(left, right) {
  const leftDirection = unitDirection(left.a, left.b)
  const rightDirection = unitDirection(right.a, right.b)
  if (Math.abs(Math.abs(leftDirection.x * rightDirection.x + leftDirection.y * rightDirection.y) - 1) > 0.02) return Infinity
  return Math.min(
    pointSegmentDistance(left.a, right.a, right.b),
    pointSegmentDistance(left.b, right.a, right.b),
    pointSegmentDistance(right.a, left.a, left.b),
    pointSegmentDistance(right.b, left.a, left.b)
  )
}

function pointSegmentDistance(point, a, b) {
  const dx = b.x - a.x
  const dy = b.y - a.y
  const lengthSquared = dx * dx + dy * dy
  if (lengthSquared === 0) return directDistance(point, a)
  const t = Math.max(0, Math.min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared))
  return directDistance(point, { x: a.x + t * dx, y: a.y + t * dy })
}

function rangesOverlap(a1, a2, b1, b2) {
  return Math.max(0, Math.min(Math.max(a1, a2), Math.max(b1, b2)) - Math.max(Math.min(a1, a2), Math.min(b1, b2)))
}

function directDistance(a, b) {
  if (!a || !b) return 0
  return Math.hypot(b.x - a.x, b.y - a.y)
}

function unitDirection(from, to) {
  const length = directDistance(from, to) || 1
  return { x: (to.x - from.x) / length, y: (to.y - from.y) / length }
}

function nearlyEqual(left, right) {
  return Math.abs(left - right) < 0.5
}

function uniqueNumbers(values) {
  return [...new Set(values.map((value) => Math.round(value * 10) / 10))]
}

function uniqueRoutes(routes) {
  const seen = new Set()
  return routes.filter((route) => {
    const key = route.map((point) => `${Math.round(point.x)},${Math.round(point.y)}`).join("|")
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })
}

function compactPolyline(points) {
  const compacted = compactPoints(points)
  return compacted.filter((point, index) => {
    if (index === 0 || index === compacted.length - 1) return true
    const previous = compacted[index - 1]
    const next = compacted[index + 1]
    const cross = (point.x - previous.x) * (next.y - point.y) - (point.y - previous.y) * (next.x - point.x)
    return Math.abs(cross) > 0.01
  })
}

function compactPoints(points) {
  return points.filter((point, index) => {
    if (index === 0) return true
    const previous = points[index - 1]
    return point.x !== previous.x || point.y !== previous.y
  })
}

function compareEdges(a, b, nodesById) {
  const kindDifference = edgePriority(a) - edgePriority(b)
  return kindDifference || compareNodes(nodesById.get(a.target), nodesById.get(b.target))
}

function edgePriority(edge) {
  return edge.kind === "hierarchy" ? 0 : 1
}

function compareNodes(a, b) {
  const positionDifference = numericPosition(a?.position) - numericPosition(b?.position)
  if (positionDifference) return positionDifference
  return (a?.label || "").localeCompare(b?.label || "", "it")
}

function numericPosition(value) {
  if (value === null || value === undefined || value === "") return Number.MAX_SAFE_INTEGER
  return Number.isFinite(Number(value)) ? Number(value) : Number.MAX_SAFE_INTEGER
}
