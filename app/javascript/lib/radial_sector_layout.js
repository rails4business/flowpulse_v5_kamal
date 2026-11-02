export function buildRadialSupportTree({
  focusId,
  nodeIds,
  hierarchyEdges = [],
  contextualEdges = [],
  directedHierarchy = false,
  terminalRootParents = false,
  compareNodeIds = (a, b) => a.localeCompare(b)
}) {
  const available = new Set(nodeIds)
  const childrenById = new Map(nodeIds.map((nodeId) => [nodeId, []]))
  const depthById = new Map([[focusId, 0]])
  const ringNodeIds = new Map()
  const supportEdgeByChild = new Map()
  const supportEdgeIds = new Set()
  const visited = new Set([focusId])
  const adjacency = new Map(nodeIds.map((nodeId) => [nodeId, []]))
  hierarchyEdges.forEach((edge) => {
    if (!available.has(edge.source) || !available.has(edge.target)) return
    adjacency.get(edge.source).push({ nodeId: edge.target, edge })
    if (!directedHierarchy) adjacency.get(edge.target).push({ nodeId: edge.source, edge })
  })
  adjacency.forEach((entries) => entries.sort((a, b) => compareNodeIds(a.nodeId, b.nodeId)))

  const attach = (parentId, nodeId, edge = null) => {
    if (visited.has(nodeId)) return false
    visited.add(nodeId)
    const ring = (depthById.get(parentId) || 0) + 1
    depthById.set(nodeId, ring)
    childrenById.get(parentId).push(nodeId)
    ringNodeIds.set(ring, [...(ringNodeIds.get(ring) || []), nodeId])
    if (edge) {
      supportEdgeByChild.set(nodeId, edge)
      supportEdgeIds.add(edge.id)
    }
    return true
  }

  const directContext = contextualEdges.filter((edge) => (
    (edge.source === focusId && available.has(edge.target)) ||
    (edge.target === focusId && available.has(edge.source))
  )).map((edge) => ({
    nodeId: edge.source === focusId ? edge.target : edge.source,
    edge
  })).sort((a, b) => compareNodeIds(a.nodeId, b.nodeId))
  directContext.forEach(({ nodeId, edge }) => attach(focusId, nodeId, edge))

  if (terminalRootParents) {
    hierarchyEdges.filter((edge) => edge.target === focusId && available.has(edge.source))
      .sort((a, b) => compareNodeIds(a.source, b.source))
      .forEach((edge) => attach(focusId, edge.source, edge))
  }

  // Direct Node Links and direct parents form the first-ring frontier in the
  // focused view. Only the centered node and its real descendants may expand.
  const queue = directedHierarchy ? [focusId] : [focusId, ...directContext.map(({ nodeId }) => nodeId)]
  while (queue.length) {
    const currentId = queue.shift()
    ;(adjacency.get(currentId) || []).forEach(({ nodeId, edge }) => {
      if (!attach(currentId, nodeId, edge)) return
      queue.push(nodeId)
    })
  }

  const excludedNodeIds = nodeIds.filter((nodeId) => !visited.has(nodeId)).sort(compareNodeIds)
  if (!directedHierarchy) excludedNodeIds.forEach((nodeId) => attach(focusId, nodeId))

  return { childrenById, depthById, ringNodeIds, supportEdgeByChild, supportEdgeIds, excludedNodeIds }
}

export function calculateRadialSectorLayout({
  focusId,
  nodeIds,
  childrenById,
  depthById,
  ringNodeIds,
  rootDirections = {},
  continuationById = {},
  dimensionsByRing,
  nodeDimensionsById = {},
  groupById = {},
  collisionMargin = 21,
  firstRingCollisionMargin = 10,
  minimumRingGap = 36
}) {
  const positions = { [focusId]: { x: 0, y: 0 } }
  const radii = new Map([[0, 0]])
  const angles = new Map()
  const maxDepth = Math.max(0, ...ringNodeIds.keys())

  for (let ring = 1; ring <= maxDepth; ring += 1) radii.set(ring, ring === 1 ? 230 : radii.get(ring - 1) + 196)

  const dimensionsFor = (nodeId, ring) => nodeDimensionsById[nodeId] || dimensionsByRing(ring)
  const marginForRing = (ring) => ring === 1 ? firstRingCollisionMargin : collisionMargin
  const boxAt = (nodeId, ring, radius) => {
    const angle = angles.get(nodeId)
    const dimensions = dimensionsFor(nodeId, ring)
    const x = Math.cos(angle) * radius
    const y = Math.sin(angle) * radius
    const margin = marginForRing(ring)
    return {
      nodeId,
      x,
      y,
      left: x - dimensions.width / 2 - margin,
      right: x + dimensions.width / 2 + margin,
      top: y - dimensions.height / 2 - margin,
      bottom: y + dimensions.height / 2 + margin
    }
  }
  const boxesOverlap = (first, second) => !(
    first.right <= second.left || first.left >= second.right ||
    first.bottom <= second.top || first.top >= second.bottom
  )
  const angularFootprint = (nodeId, ring) => {
    const dimensions = dimensionsFor(nodeId, ring)
    const radius = Math.max(1, radii.get(ring) || 1)
    const tangentialSize = dimensions.width + marginForRing(ring) * 2
    return 2 * Math.asin(Math.min(1, tangentialSize / (2 * radius)))
  }
  const angularGap = (ring) => {
    const radius = Math.max(1, radii.get(ring) || 1)
    return 2 * Math.asin(Math.min(1, marginForRing(ring) / (2 * radius)))
  }
  const childOffsets = new Map()
  let sectorProfiles = new Map()
  let completedIterations = 0
  let radiusExpansions = 0
  let collisionChecks = 0

  const shiftedProfile = (profile, offset) => new Map(
    [...profile].map(([ring, interval]) => [
      ring,
      { min: interval.min + offset, max: interval.max + offset }
    ])
  )
  const mergeProfile = (target, profile) => {
    profile.forEach((interval, ring) => {
      const current = target.get(ring)
      target.set(ring, current
        ? { min: Math.min(current.min, interval.min), max: Math.max(current.max, interval.max) }
        : { ...interval })
    })
  }
  const packProfiles = (items) => {
    if (!items.length) return { offsets: [], profile: new Map() }

    const aggregate = new Map()
    const offsets = []
    items.forEach((item, index) => {
      let offset = 0
      if (index > 0) {
        const previousGroup = groupById[items[index - 1].childId]
        const currentGroup = groupById[item.childId]
        const crossesGroup = previousGroup && currentGroup && previousGroup !== currentGroup
        item.profile.forEach((interval, ring) => {
          const occupied = aggregate.get(ring)
          if (!occupied) return
          const separation = angularGap(ring) * (crossesGroup ? 2.5 : 1)
          offset = Math.max(offset, occupied.max + separation - interval.min)
        })
      }
      offsets.push(offset)
      mergeProfile(aggregate, shiftedProfile(item.profile, offset))
    })

    const bounds = [...aggregate.values()].reduce((result, interval) => ({
      min: Math.min(result.min, interval.min),
      max: Math.max(result.max, interval.max)
    }), { min: Number.POSITIVE_INFINITY, max: Number.NEGATIVE_INFINITY })
    const center = Number.isFinite(bounds.min) ? (bounds.min + bounds.max) / 2 : 0
    return {
      offsets: offsets.map((offset) => offset - center),
      profile: shiftedProfile(aggregate, -center)
    }
  }
  const packAroundContinuation = (items, continuationId) => {
    const continuationIndex = items.findIndex((item) => item.childId === continuationId)
    if (continuationIndex < 0) return packProfiles(items)

    const continuation = items[continuationIndex]
    const aggregate = shiftedProfile(continuation.profile, 0)
    const offsetsById = new Map([[continuation.childId, 0]])
    let side = -1
    items.filter((_, index) => index !== continuationIndex).forEach((item) => {
      let offset = 0
      item.profile.forEach((interval, ring) => {
        const occupied = aggregate.get(ring)
        if (!occupied) return
        if (side < 0) offset = Math.min(offset, occupied.min - angularGap(ring) - interval.max)
        else offset = Math.max(offset, occupied.max + angularGap(ring) - interval.min)
      })
      offsetsById.set(item.childId, offset)
      mergeProfile(aggregate, shiftedProfile(item.profile, offset))
      side *= -1
    })
    return {
      offsets: items.map((item) => offsetsById.get(item.childId)),
      profile: aggregate
    }
  }

  const calculateCones = () => {
    childOffsets.clear()
    sectorProfiles = new Map()
    const calculateSubtree = (nodeId) => {
      const nodeChildren = childrenById.get(nodeId) || []
      const nodeRing = depthById.get(nodeId) || 0
      const ownWidth = nodeRing > 0 ? angularFootprint(nodeId, nodeRing) : 0
      const profile = new Map()
      if (nodeRing > 0) profile.set(nodeRing, { min: -ownWidth / 2, max: ownWidth / 2 })
      if (!nodeChildren.length) {
        sectorProfiles.set(nodeId, profile)
        return profile
      }

      const childItems = nodeChildren.map((childId) => ({
        childId,
        profile: calculateSubtree(childId)
      }))
      const packed = continuationById[nodeId]
        ? packAroundContinuation(childItems, continuationById[nodeId])
        : packProfiles(childItems)
      childItems.forEach((item, index) => childOffsets.set(item.childId, packed.offsets[index]))
      mergeProfile(profile, packed.profile)
      sectorProfiles.set(nodeId, profile)
      return profile
    }

    const rootChildren = childrenById.get(focusId) || []
    const incoming = rootChildren.filter((childId) => rootDirections[childId] !== "outgoing")
    const outgoing = rootChildren.filter((childId) => rootDirections[childId] === "outgoing")
    const assignRootGroup = (group, centerAngle) => {
      if (!group.length) return
      const items = group.map((childId) => ({ childId, profile: calculateSubtree(childId) }))
      const continuationId = continuationById[focusId]
      const packed = continuationId && group.includes(continuationId)
        ? packAroundContinuation(items, continuationId)
        : packProfiles(items)
      items.forEach((item, index) => {
        childOffsets.set(item.childId, centerAngle + packed.offsets[index])
      })
    }
    assignRootGroup(incoming, -Math.PI / 2)
    assignRootGroup(outgoing, Math.PI / 2)
    sectorProfiles.set(focusId, new Map())

    angles.set(focusId, 0)
    const assignAngles = (nodeId) => {
      const baseAngle = angles.get(nodeId) || 0
      ;(childrenById.get(nodeId) || []).forEach((childId) => {
        angles.set(childId, baseAngle + (childOffsets.get(childId) || 0))
        assignAngles(childId)
      })
    }
    assignAngles(focusId)
  }

  const solveRadii = () => {
    const selectedDimensions = dimensionsFor(focusId, 0)
    const selectedMargin = marginForRing(0)
    const selectedBox = {
      left: -selectedDimensions.width / 2 - selectedMargin,
      right: selectedDimensions.width / 2 + selectedMargin,
      top: -selectedDimensions.height / 2 - selectedMargin,
      bottom: selectedDimensions.height / 2 + selectedMargin
    }

    const radialExtent = (nodeId, ring) => {
      const dimensions = dimensionsFor(nodeId, ring)
      const angle = angles.get(nodeId) || 0
      return (
        Math.abs(Math.cos(angle)) * dimensions.width +
        Math.abs(Math.sin(angle)) * dimensions.height
      ) / 2 + marginForRing(ring)
    }
    const maximumRadialExtent = (ring) => Math.max(
      0,
      ...(ringNodeIds.get(ring) || []).map((nodeId) => radialExtent(nodeId, ring))
    )
    const rootExtent = Math.max(selectedDimensions.width, selectedDimensions.height) / 2 + selectedMargin
    let maximumChange = 0

    for (let ring = 1; ring <= maxDepth; ring += 1) {
      const ringIds = ringNodeIds.get(ring) || []
      const previousRadius = ring === 1 ? 0 : radii.get(ring - 1)
      const previousExtent = ring === 1 ? rootExtent : maximumRadialExtent(ring - 1)
      const baseRadius = previousRadius + previousExtent + maximumRadialExtent(ring) + minimumRingGap
      const fitsAt = (radius) => {
        collisionChecks += 1
        const boxes = ringIds.map((nodeId) => boxAt(nodeId, ring, radius))
        for (let index = 0; index < boxes.length; index += 1) {
          if (ring === 1 && boxesOverlap(boxes[index], selectedBox)) return false
          for (let other = index + 1; other < boxes.length; other += 1) {
            if (boxesOverlap(boxes[index], boxes[other])) return false
          }
        }
        return true
      }

      let radius = baseRadius
      if (!fitsAt(radius)) {
        radiusExpansions += 1
        let lower = radius
        let upper = Math.max(radius + 24, radius * 1.12)
        let attempts = 0
        while (!fitsAt(upper) && attempts < 18) {
          lower = upper
          upper = upper * 1.22 + 12
          attempts += 1
        }
        if (fitsAt(upper)) {
          for (let step = 0; step < 18; step += 1) {
            const middle = (lower + upper) / 2
            if (fitsAt(middle)) upper = middle
            else lower = middle
          }
          radius = upper
        } else {
          radius = upper
        }
      }
      maximumChange = Math.max(maximumChange, Math.abs(radius - (radii.get(ring) || 0)))
      radii.set(ring, radius)
    }
    return maximumChange
  }

  for (let iteration = 0; iteration < 14; iteration += 1) {
    completedIterations = iteration + 1
    calculateCones()
    const change = solveRadii()
    if (change < 0.25) break
  }
  // The last radius adjustment changes angular card footprints slightly.
  // Recalculate once so returned angles and sector diagnostics match the
  // final orbital radii exactly.
  calculateCones()

  nodeIds.filter((nodeId) => nodeId !== focusId).forEach((nodeId) => {
    const ring = depthById.get(nodeId)
    const box = boxAt(nodeId, ring, radii.get(ring))
    positions[nodeId] = { x: box.x, y: box.y }
  })

  const sectors = new Map([...sectorProfiles].map(([nodeId, profile]) => {
    const baseAngle = angles.get(nodeId) || 0
    return [nodeId, shiftedProfile(profile, baseAngle)]
  }))
  const diagnostics = {
    nodes: nodeIds.length,
    rings: maxDepth,
    iterations: completedIterations,
    radiusExpansions,
    collisionChecks,
    maximumRadius: Math.max(0, ...radii.values())
  }
  return { positions, radii, angles, sectors, diagnostics }
}
