import evaluator
import mutable_dict

pub const builtins = [
  #(
    "coquette_squirrel",
    "fn draw(shape_slider: Int) -> List(Path) {
  let w = 2 + shape_slider / 50
  [
    Path(Line(Point(0, 40), Point(0, -20)), 0, 10, w),
    Path(Line(Point(0, 40), Point(-30, 10)), 0, 10, w),
    Path(Line(Point(0, 40), Point(30, 10)), 0, 10, w),
    Path(Line(Point(-30, 10), Point(0, -20)), 0, 10, w),
    Path(Line(Point(30, 10), Point(0, -20)), 0, 10, w),
    Path(Line(Point(-15, 40), Point(-25, 60)), 0, 10, w),
    Path(Line(Point(-25, 60), Point(-5, 45)), 0, 10, w),
    Path(Line(Point(15, 40), Point(25, 60)), 0, 10, w),
    Path(Line(Point(25, 60), Point(5, 45)), 0, 10, w),
    Path(Line(Point(-8, 42), Point(8, 42)), 0, 8, w),
    Path(Line(Point(-8, 42), Point(-18, 48)), 0, 8, w),
    Path(Line(Point(8, 42), Point(18, 48)), 0, 8, w),
    Path(Line(Point(-10, 25), Point(-10, 20)), 0, 10, w),
    Path(Line(Point(10, 25), Point(10, 20)), 0, 10, w),
    Path(Line(Point(-5, 12), Point(5, 12)), 0, 10, w),
    Path(Line(Point(0, 12), Point(0, 5)), 0, 10, w),
    Path(Line(Point(20, -10), Point(70, -20)), 0, 15, w),
    Path(Line(Point(70, -20), Point(90, 20)), 2, 18, w),
    Path(Line(Point(90, 20), Point(60, 70)), 4, 20, w),
    Path(Line(Point(60, 70), Point(10, 60)), 6, 22, w),
    Path(Line(Point(10, 60), Point(35, 25)), 8, 25, w),
    Path(Line(Point(-150, -40), Point(150, -40)), 0, 5, w),
    Path(Line(Point(-100, -40), Point(-110, -20)), 0, 8, w),
    Path(Line(Point(-100, -40), Point(-90, -20)), 0, 8, w),
    Path(Line(Point(100, -40), Point(90, -20)), 0, 8, w),
    Path(Line(Point(100, -40), Point(110, -20)), 0, 8, w)
  ]
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
      let len = { i / 2 + 1 } * 12
      let q = Point(p.x + d.x * len, p.y + d.y * len)
      [
        Path(Line(p, q), i * 2, i * 2 + 5, 3),
        ..spiral(q, Point(0 - d.y, d.x), i + 1, n)
      ]
    }
  }
}
",
  ),
]

pub fn global_frame() -> evaluator.GlobalFrame {
  mutable_dict.new()
}
