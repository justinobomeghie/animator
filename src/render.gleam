//// Convert each shape into a list of points called a RenderPath.

import gleam/int
import gleam/list
import shape.{type Path, type Point, Cubic, Line, Point}

/// One path as canvas.mjs setDrawing consumes it (field by field): the
/// polyline, stroke colour/width, and the start and end times (in tenths of a second)
/// between which the reveal runs — so the renderer's clock needs no shape
/// knowledge.
pub type RenderPath {
  RenderPath(
    points: List(Point),
    thickness: Float,
    color: String,
    start: Float,
    end: Float,
  )
}

// ── The canvas (canvas.mjs) ───────────────────────────────────────────────────

/// Replace the drawing being animated in the page's
/// `<canvas id="animation-canvas">` element. If that element doesn't appear within
/// about 10 seconds, this logs an error to the browser console. This keeps the
/// current time, so a drawing that replaces a finished one appears complete. To
/// animate it from the start, also call reset_clock.
@external(javascript, "./canvas.mjs", "setDrawing")
pub fn set_drawing(paths: List(RenderPath)) -> Nil

/// Set the animation's speed, as a multiple of its normal speed: 1.0 is normal and
/// is where it starts, 0.0 pauses, and a negative rate plays it backward.
/// Time stops at the start of the drawing and when its last path finishes, so
/// playing a finished drawing again takes a call to reset_clock.
@external(javascript, "./canvas.mjs", "setSpeed")
pub fn set_speed(rate: Float) -> Nil

/// Jump the animation back to its start, where the canvas is empty.
@external(javascript, "./canvas.mjs", "resetClock")
pub fn reset_clock() -> Nil

/// Repeat a timed drawing after its paths finish, with a short completed hold.
@external(javascript, "./canvas.mjs", "setLooping")
pub fn set_looping(enabled: Bool) -> Nil

/// Render the flower with pink petals, a green stem and leaves, and a golden
/// center. Its source path start times mark those drawing stages.
pub fn render_flower_path(path: Path) -> RenderPath {
  let color = case path.start <. 4.0 {
    True -> "#B96585"
    False -> case path.start <. 40.0 {
      True -> case path.thickness >=. 2.0 {
        True -> "#789B73"
        False -> "#A8BE96"
      }
      False -> case path.start <. 50.0 {
        True -> "#D98FA9"
        False -> case path.start <. 66.0 {
          True -> "#D98FA9"
          False -> case path.start <. 95.0 {
            True -> "#C77995"
            False -> "#F0BFD0"
          }
        }
      }
    }
  }
  render_path(path, color)
}

pub fn render_path(path: Path, color: String) -> RenderPath {
  case path.shape {
    Line(a, b) ->
      RenderPath([a, b], path.thickness, color, path.start, path.end)
    Cubic(a, b, c, d) ->
      RenderPath(
        cubic_points(0, a, b, c, d, []),
        path.thickness,
        color,
        path.start,
        path.end,
      )
  }
}

fn cubic_points(
  index: Int,
  start: Point,
  control1: Point,
  control2: Point,
  end: Point,
  points: List(Point),
) -> List(Point) {
  case index > 16 {
    True -> list.reverse(points)
    False -> {
      let t = int.to_float(index) /. 16.0
      let u = 1.0 -. t
      let u2 = u *. u
      let t2 = t *. t
      let x = u2 *. u *. start.x
        +. 3.0 *. u2 *. t *. control1.x
        +. 3.0 *. u *. t2 *. control2.x
        +. t2 *. t *. end.x
      let y = u2 *. u *. start.y
        +. 3.0 *. u2 *. t *. control1.y
        +. 3.0 *. u *. t2 *. control2.y
        +. t2 *. t *. end.y
      cubic_points(index + 1, start, control1, control2, end, [Point(x, y), ..points])
    }
  }
}
