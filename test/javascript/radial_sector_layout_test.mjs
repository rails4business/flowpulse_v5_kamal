import assert from "node:assert/strict"
import test from "node:test"

import {
  buildRadialSupportTree,
  calculateRadialSectorLayout
} from "../../app/javascript/lib/radial_sector_layout.js"

const dimensionsByRing = (ring) => {
  if (ring === 0) return { width: 210, height: 70 }
  if (ring === 1) return { width: 184, height: 62 }
  return { width: 166, height: 56 }
}

function layout(overrides = {}) {
  return calculateRadialSectorLayout({
    focusId: "root",
    nodeIds: ["root", "parent", "child"],
    childrenById: new Map([
      ["root", ["parent"]],
      ["parent", ["child"]],
      ["child", []]
    ]),
    depthById: new Map([
      ["root", 0],
      ["parent", 1],
      ["child", 2]
    ]),
    ringNodeIds: new Map([
      [1, ["parent"]],
      [2, ["child"]]
    ]),
    rootDirections: { parent: "outgoing" },
    dimensionsByRing,
    ...overrides
  })
}

test("keeps the focus at the origin and uses increasing orbital radii", () => {
  const result = layout()

  assert.deepEqual(result.positions.root, { x: 0, y: 0 })
  assert.ok(result.radii.get(1) > 0)
  assert.ok(result.radii.get(2) > result.radii.get(1))
})

test("keeps a single-child branch on one coherent ray", () => {
  const result = layout()

  assert.equal(result.angles.get("parent"), result.angles.get("child"))
})

test("separates incoming and outgoing root sectors", () => {
  const result = layout({
    nodeIds: ["root", "incoming", "outgoing"],
    childrenById: new Map([
      ["root", ["incoming", "outgoing"]],
      ["incoming", []],
      ["outgoing", []]
    ]),
    depthById: new Map([
      ["root", 0],
      ["incoming", 1],
      ["outgoing", 1]
    ]),
    ringNodeIds: new Map([[1, ["incoming", "outgoing"]]]),
    rootDirections: { incoming: "incoming", outgoing: "outgoing" }
  })

  assert.ok(result.positions.incoming.y < 0)
  assert.ok(result.positions.outgoing.y > 0)
})

test("produces deterministic positions", () => {
  assert.deepEqual(layout().positions, layout().positions)
})

test("keeps ordered sibling subtrees separated on every shared ring", () => {
  const result = layout({
    nodeIds: ["root", "left", "right", "left-a", "left-b", "right-a"],
    childrenById: new Map([
      ["root", ["left", "right"]],
      ["left", ["left-a", "left-b"]],
      ["right", ["right-a"]],
      ["left-a", []],
      ["left-b", []],
      ["right-a", []]
    ]),
    depthById: new Map([
      ["root", 0],
      ["left", 1],
      ["right", 1],
      ["left-a", 2],
      ["left-b", 2],
      ["right-a", 2]
    ]),
    ringNodeIds: new Map([
      [1, ["left", "right"]],
      [2, ["left-a", "left-b", "right-a"]]
    ]),
    rootDirections: { left: "outgoing", right: "outgoing" }
  })

  assert.ok(result.angles.get("left") < result.angles.get("right"))
  const leftSector = result.sectors.get("left")
  const rightSector = result.sectors.get("right")
  for (const ring of [1, 2]) {
    assert.ok(leftSector.get(ring).max < rightSector.get(ring).min)
  }
})

test("uses only visible descendants to determine the cone width", () => {
  const shallow = layout({
    nodeIds: ["root", "left", "right"],
    childrenById: new Map([
      ["root", ["left", "right"]],
      ["left", []],
      ["right", []]
    ]),
    depthById: new Map([["root", 0], ["left", 1], ["right", 1]]),
    ringNodeIds: new Map([[1, ["left", "right"]]]),
    rootDirections: { left: "outgoing", right: "outgoing" }
  })
  const deep = layout({
    nodeIds: ["root", "left", "right", "a", "b", "c"],
    childrenById: new Map([
      ["root", ["left", "right"]],
      ["left", ["a", "b", "c"]],
      ["right", []],
      ["a", []],
      ["b", []],
      ["c", []]
    ]),
    depthById: new Map([
      ["root", 0], ["left", 1], ["right", 1],
      ["a", 2], ["b", 2], ["c", 2]
    ]),
    ringNodeIds: new Map([
      [1, ["left", "right"]],
      [2, ["a", "b", "c"]]
    ]),
    rootDirections: { left: "outgoing", right: "outgoing" }
  })

  assert.deepEqual([...shallow.sectors.get("left").keys()], [1])
  assert.deepEqual([...deep.sectors.get("left").keys()], [1, 2])
})

test("expands a dense ring only until its cards stop overlapping", () => {
  const children = Array.from({ length: 10 }, (_, index) => `node-${index}`)
  const result = layout({
    nodeIds: ["root", ...children],
    childrenById: new Map([
      ["root", children],
      ...children.map((nodeId) => [nodeId, []])
    ]),
    depthById: new Map([["root", 0], ...children.map((nodeId) => [nodeId, 1])]),
    ringNodeIds: new Map([[1, children]]),
    rootDirections: Object.fromEntries(children.map((nodeId) => [nodeId, "outgoing"]))
  })

  const boxes = children.map((nodeId) => ({
    left: result.positions[nodeId].x - 184 / 2 - 10,
    right: result.positions[nodeId].x + 184 / 2 + 10,
    top: result.positions[nodeId].y - 62 / 2 - 10,
    bottom: result.positions[nodeId].y + 62 / 2 + 10
  }))
  for (let index = 0; index < boxes.length; index += 1) {
    for (let other = index + 1; other < boxes.length; other += 1) {
      const separate = boxes[index].right <= boxes[other].left || boxes[index].left >= boxes[other].right ||
        boxes[index].bottom <= boxes[other].top || boxes[index].top >= boxes[other].bottom
      assert.ok(separate, `node ${index} overlaps node ${other}`)
    }
  }
})

test("uses the actual dimensions of individual cards", () => {
  const result = layout({
    nodeIds: ["root", "wide", "normal"],
    childrenById: new Map([["root", ["wide", "normal"]], ["wide", []], ["normal", []]]),
    depthById: new Map([["root", 0], ["wide", 1], ["normal", 1]]),
    ringNodeIds: new Map([[1, ["wide", "normal"]]]),
    rootDirections: { wide: "outgoing", normal: "outgoing" },
    nodeDimensionsById: { wide: { width: 320, height: 80 } }
  })

  const wideInterval = result.sectors.get("wide").get(1)
  const normalInterval = result.sectors.get("normal").get(1)
  assert.ok(wideInterval.max - wideInterval.min > normalInterval.max - normalInterval.min)
})

test("keeps adjacent rings at the requested radial clearance", () => {
  const result = layout()
  const distance = result.radii.get(2) - result.radii.get(1)

  assert.ok(distance >= 126)
})

test("keeps a direct node link on the first ring without replacing hierarchy edges", () => {
  const tree = buildRadialSupportTree({
    focusId: "root",
    nodeIds: ["root", "parent", "linked"],
    hierarchyEdges: [
      { id: "h-1", source: "root", target: "parent" },
      { id: "h-2", source: "parent", target: "linked" }
    ],
    contextualEdges: [{ id: "bridge", source: "root", target: "linked" }]
  })

  assert.equal(tree.depthById.get("linked"), 1)
  assert.deepEqual(tree.childrenById.get("root"), ["linked", "parent"])
  assert.ok(tree.supportEdgeIds.has("bridge"))
  assert.ok(tree.supportEdgeIds.has("h-1"))
  assert.ok(!tree.supportEdgeIds.has("h-2"))
})

test("chooses one deterministic support edge from a cyclic graph", () => {
  const tree = buildRadialSupportTree({
    focusId: "root",
    nodeIds: ["root", "a", "b", "orphan"],
    hierarchyEdges: [
      { id: "root-a", source: "root", target: "a" },
      { id: "root-b", source: "root", target: "b" },
      { id: "a-b", source: "a", target: "b" }
    ]
  })

  assert.equal(tree.supportEdgeIds.size, 2)
  assert.deepEqual(tree.childrenById.get("root"), ["a", "b", "orphan"])
  assert.equal(tree.depthById.get("orphan"), 1)
})

test("adds clearance between different domain groups", () => {
  const options = {
    nodeIds: ["root", "a", "b"],
    childrenById: new Map([["root", ["a", "b"]], ["a", []], ["b", []]]),
    depthById: new Map([["root", 0], ["a", 1], ["b", 1]]),
    ringNodeIds: new Map([[1, ["a", "b"]]]),
    rootDirections: { a: "outgoing", b: "outgoing" }
  }
  const sameGroup = layout({ ...options, groupById: { a: "one", b: "one" } })
  const separateGroups = layout({ ...options, groupById: { a: "one", b: "two" } })

  const sameOpening = sameGroup.angles.get("b") - sameGroup.angles.get("a")
  const separateOpening = separateGroups.angles.get("b") - separateGroups.angles.get("a")
  assert.ok(separateOpening > sameOpening)
})

test("keeps diagnostics bounded on a large balanced tree", () => {
  const nodeIds = ["root"]
  const childrenById = new Map([["root", []]])
  const depthById = new Map([["root", 0]])
  const ringNodeIds = new Map()
  let frontier = ["root"]
  for (let depth = 1; depth <= 4; depth += 1) {
    const next = []
    frontier.forEach((parentId) => {
      const children = Array.from({ length: 3 }, (_, index) => `${parentId}-${index}`)
      childrenById.set(parentId, children)
      children.forEach((nodeId) => {
        nodeIds.push(nodeId)
        next.push(nodeId)
        childrenById.set(nodeId, [])
        depthById.set(nodeId, depth)
        ringNodeIds.set(depth, [...(ringNodeIds.get(depth) || []), nodeId])
      })
    })
    frontier = next
  }
  const result = layout({ nodeIds, childrenById, depthById, ringNodeIds })

  assert.equal(result.diagnostics.nodes, 121)
  assert.ok(result.diagnostics.iterations <= 14)
  assert.ok(Number.isFinite(result.diagnostics.maximumRadius))
})

test("stops Node Links and parents at the first ring in focused mode", () => {
  const tree = buildRadialSupportTree({
    focusId: "root",
    nodeIds: ["root", "parent", "parent-child", "child", "canonical", "alias"],
    hierarchyEdges: [
      { id: "parent-root", source: "parent", target: "root" },
      { id: "parent-other", source: "parent", target: "parent-child" },
      { id: "root-child", source: "root", target: "child" },
      { id: "child-canonical", source: "child", target: "canonical" }
    ],
    contextualEdges: [{ id: "node-link", source: "root", target: "alias" }],
    directedHierarchy: true,
    terminalRootParents: true
  })

  assert.equal(tree.depthById.get("alias"), 1)
  assert.deepEqual(tree.childrenById.get("alias"), [])
  assert.equal(tree.depthById.get("parent"), 1)
  assert.deepEqual(tree.childrenById.get("parent"), [])
  assert.equal(tree.depthById.get("child"), 1)
  assert.equal(tree.depthById.get("canonical"), 2)
  assert.deepEqual(tree.excludedNodeIds, ["parent-child"])
})

test("keeps the next course on the parent ray and branches chapters sideways", () => {
  const result = layout({
    nodeIds: ["root", "course", "chapter-a", "next-course", "chapter-b"],
    childrenById: new Map([
      ["root", ["course"]],
      ["course", ["chapter-a", "next-course", "chapter-b"]],
      ["chapter-a", []],
      ["next-course", []],
      ["chapter-b", []]
    ]),
    depthById: new Map([
      ["root", 0], ["course", 1],
      ["chapter-a", 2], ["next-course", 2], ["chapter-b", 2]
    ]),
    ringNodeIds: new Map([
      [1, ["course"]],
      [2, ["chapter-a", "next-course", "chapter-b"]]
    ]),
    rootDirections: { course: "outgoing" },
    continuationById: { course: "next-course" }
  })

  assert.equal(result.angles.get("course"), result.angles.get("next-course"))
  assert.ok(result.angles.get("chapter-a") < result.angles.get("course"))
  assert.ok(result.angles.get("chapter-b") > result.angles.get("course"))
})

test("keeps the course continuation centered when the course is the focus", () => {
  const result = layout({
    nodeIds: ["root", "chapter-a", "next-course", "chapter-b"],
    childrenById: new Map([
      ["root", ["chapter-a", "next-course", "chapter-b"]],
      ["chapter-a", []], ["next-course", []], ["chapter-b", []]
    ]),
    depthById: new Map([
      ["root", 0], ["chapter-a", 1], ["next-course", 1], ["chapter-b", 1]
    ]),
    ringNodeIds: new Map([[1, ["chapter-a", "next-course", "chapter-b"]]]),
    rootDirections: { "chapter-a": "outgoing", "next-course": "outgoing", "chapter-b": "outgoing" },
    continuationById: { root: "next-course" }
  })

  assert.equal(result.angles.get("next-course"), Math.PI / 2)
  assert.ok(result.angles.get("chapter-a") < result.angles.get("next-course"))
  assert.ok(result.angles.get("chapter-b") > result.angles.get("next-course"))
})

