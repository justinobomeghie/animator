//// The built-in functions of the draw mini-language.

import evaluator.{type GlobalFrame}
import mutable_dict

pub fn global_frame() -> GlobalFrame {
  let frame = mutable_dict.new()
  frame
}

pub const builtins = [
  #(
    "coquette_squirrel",
    "fn draw(shape_slider: Int) -> List(Path) {
  let w = 3 + shape_slider / 50

  [
    Path(Line(Point(-30, 20), Point(30, 20)), 0, 10, w),
    Path(Line(Point(30, 20), Point(50, -10)), 0, 10, w),
    Path(Line(Point(50, -10), Point(30, -40)), 0, 10, w),
    Path(Line(Point(30, -40), Point(-30, -40)), 0, 10, w),
    Path(Line(Point(-30, -40), Point(-50, -10)), 0, 10, w),
    Path(Line(Point(-50, -10), Point(-30, 20)), 0, 10, w),

    Path(Line(Point(-35, 20), Point(-45, 55)), 2, 12, w),
    Path(Line(Point(-45, 55), Point(-20, 35)), 2, 12, w),
    Path(Line(Point(35, 20), Point(45, 55)), 2, 12, w),
    Path(Line(Point(45, 55), Point(20, 35)), 2, 12, w),

    Path(Line(Point(25, 40), Point(15, 50)), 5, 15, w),
    Path(Line(Point(15, 50), Point(25, 60)), 5, 15, w),
    Path(Line(Point(25, 60), Point(25, 40)), 5, 15, w),
    Path(Line(Point(25, 40), Point(35, 50)), 5, 15, w),
    Path(Line(Point(35, 50), Point(25, 60)), 5, 15, w),

    Path(Line(Point(-20, 0), Point(-15, 5)), 6, 16, w),
    Path(Line(Point(-15, 5), Point(-10, 0)), 6, 16, w),
    Path(Line(Point(10, 0), Point(15, 5)), 6, 16, w),
    Path(Line(Point(15, 5), Point(20, 0)), 6, 16, w),
    Path(Line(Point(-4, -10), Point(4, -10)), 7, 17, w),
    Path(Line(Point(4, -10), Point(0, -15)), 7, 17, w),
    Path(Line(Point(0, -15), Point(-4, -10)), 7, 17, w),
    Path(Line(Point(0, -15), Point(-8, -22)), 8, 18, w),
    Path(Line(Point(0, -15), Point(8, -22)), 8, 18, w),
    Path(Line(Point(-35, -12), Point(-25, -12)), 6, 16, w),
    Path(Line(Point(25, -12), Point(35, -12)), 6, 16, w),

    Path(Line(Point(-25, -40), Point(-35, -100)), 4, 14, w),
    Path(Line(Point(-35, -100), Point(35, -100)), 4, 14, w),
    Path(Line(Point(35, -100), Point(25, -40)), 4, 14, w),
    Path(Line(Point(-8, -65), Point(8, -65)), 8, 18, w),
    Path(Line(Point(-8, -65), Point(0, -80)), 8, 18, w),
    Path(Line(Point(8, -65), Point(0, -80)), 8, 18, w),
    Path(Line(Point(-30, -100), Point(-40, -115)), 10, 20, w),
    Path(Line(Point(-40, -115), Point(-15, -115)), 10, 20, w),
    Path(Line(Point(30, -100), Point(40, -115)), 10, 20, w),
    Path(Line(Point(40, -115), Point(15, -115)), 10, 20, w),

    Path(Line(Point(30, -90), Point(90, -70)), 10, 25, w),
    Path(Line(Point(90, -70), Point(110, -10)), 12, 27, w),
    Path(Line(Point(110, -10), Point(80, 60)), 14, 29, w),
    Path(Line(Point(80, 60), Point(20, 50)), 16, 31, w),
    Path(Line(Point(20, 50), Point(50, 10)), 18, 33, w),
    Path(Line(Point(50, 10), Point(70, 0)), 20, 35, w)
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
]
