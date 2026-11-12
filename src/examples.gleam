//// The drawings that a browser with no saved library starts with: each one's
//// name and source.

pub const all = [
  #(
    "fan",
    "fn draw(shape_slider: Int) -> List(Path) {
  fan(30, Point(-200, -200))
}

fn fan(n: Int, start: Point) -> List(Path) {
  case n > 0 {
    True -> [Path(Line(start, Point(n * 10, 200)), 0, 30, 3), ..fan(n - 1, start)]
    False -> []
  }
}
",
  ),
  #(
    "square_spiral",
    "fn draw(shape_slider: Int) -> List(Path) {
  let turns = 20 + shape_slider / 4
  spiral(Point(0, 0), Point(1, 0), 0, turns)
}

fn spiral(p: Point, d: Point, i: Int, n: Int) -> List(Path) {
  case i == n {
    True -> []
    False -> {
      let len = { i / 2 + 1 } * 24
      let q = Point(p.x + d.x * len, p.y + d.y * len)
      [
        Path(Line(p, q), i * 3, i * 3 + 3, 3),
        ..spiral(q, Point(0 - d.y, d.x), i + 1, n)
      ]
    }
  }
}
",
  ),
  #(
    "string_art",
    "fn draw(shape_slider: Int) -> List(Path) {
  let n = 8 + shape_slider / 10
  list.flatten([
    quadrant(1, 1, n, 0),
    quadrant(-1, 1, n, n + 1),
    quadrant(-1, -1, n, { n + 1 } * 2),
    quadrant(1, -1, n, { n + 1 } * 3),
  ])
}

fn quadrant(sx: Int, sy: Int, n: Int, base: Int) -> List(Path) {
  strings(0, sx, sy, n, base)
}

fn strings(i: Int, sx: Int, sy: Int, n: Int, base: Int) -> List(Path) {
  case i > n {
    True -> []
    False -> {
      let a = Point(sx * 420 * i / n, 0)
      let b = Point(0, sy * 420 * { n - i } / n)
      let t = { base + i } * 2
      [Path(Line(a, b), t, t + 8, 2), ..strings(i + 1, sx, sy, n, base)]
    }
  }
}
",
  ),
  #(
    "tree",
    "fn draw(shape_slider: Int) -> List(Path) {
  let depth = 4 + shape_slider / 20
  branch(Point(0, 420), Point(0, -220), 0, depth)
}

fn branch(p: Point, d: Point, level: Int, depth: Int) -> List(Path) {
  case level == depth {
    True -> []
    False -> {
      let q = Point(p.x + d.x, p.y + d.y)
      let left = Point({ d.x - d.y } / 2, { d.y + d.x } / 2)
      let right = Point({ d.x + d.y } / 2, { d.y - d.x } / 2)
      [
        Path(Line(p, q), level * 4, level * 4 + 4, depth - level),
        ..list.append(
          branch(q, left, level + 1, depth),
          branch(q, right, level + 1, depth),
        )
      ]
    }
  }
}
",
  ),
  #(
    "storybook_flower",
    "// A single tulip grows from a seed and opens as a three-petal cup.\nfn draw(shape_slider: Int) -> List(Path) {\n  [\n    // Seed and a restrained ground mark.\n    curve(-8, 420, -15, 408, -6, 395, 4, 402, 3, 0, 2),\n    curve(4, 402, 14, 410, 10, 420, 0, 424, 2, 1, 3),\n    curve(-42, 426, -22, 423, 22, 423, 42, 426, 1, 1, 3),\n    // The stem rises in one continuous, graceful sweep.\n    curve(0, 420, 17, 260, -10, 36, 0, -205, 3, 4, 36),\n    // Long, narrow tulip leaves lift from opposite points on the stem.\n    curve(0, 242, -30, 151, -91, 17, -137, -58, 3, 18, 24),\n    curve(-137, -58, -73, -8, -29, 139, 0, 242, 3, 24, 29),\n    curve(-2, 235, -49, 137, -105, 7, -132, -49, 1, 28, 33),\n    curve(-70, 134, -88, 106, -105, 76, -116, 53, 1, 31, 35),\n    curve(3, 142, 42, 59, 100, -57, 132, -125, 3, 23, 29),\n    curve(132, -125, 86, -95, 33, 20, 3, 142, 3, 29, 34),\n    curve(6, 137, 52, 48, 102, -55, 128, -117, 1, 33, 37),\n    curve(63, 28, 82, -4, 101, -42, 115, -76, 1, 35, 39),\n    // A small closed bud forms at the top of the stem.\n    curve(0, -203, -27, -220, -25, -277, 0, -301, 3, 40, 45),\n    curve(0, -301, 25, -277, 27, -220, 0, -203, 3, 45, 50),\n    // The taller rear petal opens first, forming the tulip's crown.\n    curve(-20, -207, -65, -266, -68, -367, -16, -403, 3, 50, 56),\n    curve(-16, -403, -6, -416, 6, -416, 16, -403, 3, 56, 59),\n    curve(16, -403, 68, -367, 65, -266, 20, -207, 3, 59, 66),\n    // Left front petal curves up and inward to make one side of the cup.\n    curve(-15, -207, -83, -211, -137, -251, -148, -310, 3, 66, 71),\n    curve(-148, -310, -155, -342, -134, -360, -112, -346, 3, 71, 74),\n    curve(-112, -346, -82, -325, -54, -298, -34, -282, 3, 74, 79),\n    // The matching right petal completes the gently overlapping cup.\n    curve(15, -207, 83, -211, 137, -251, 148, -310, 3, 78, 83),\n    curve(148, -310, 155, -342, 134, -360, 112, -346, 3, 83, 86),\n    curve(112, -346, 82, -325, 54, -298, 34, -282, 3, 86, 91),\n    curve(-34, -282, -45, -257, -33, -222, -15, -207, 3, 91, 94),\n    curve(34, -282, 45, -257, 33, -222, 15, -207, 3, 91, 94),\n    // Fine folds follow the natural curve of each petal.\n    curve(0, -224, -3, -272, -2, -337, 0, -380, 1, 95, 98),\n    curve(-25, -220, -54, -243, -91, -291, -125, -331, 1, 96, 99),\n    curve(25, -220, 54, -243, 91, -291, 125, -331, 1, 97, 100),\n  ]\n}\nfn curve(x0: Int, y0: Int, x1: Int, y1: Int, x2: Int, y2: Int, x3: Int, y3: Int, width: Int, start: Int, end: Int) -> Path {\n  Path(Cubic(Point(x0, y0), Point(x1, y1), Point(x2, y2), Point(x3, y3)), start, end, width)\n}",
  ),
]
