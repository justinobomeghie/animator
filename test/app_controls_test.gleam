//// Regression coverage for the control panel and drawing source ownership.

import app
import gleam/list

pub fn speed_slider_maps_endpoints_without_changing_drawings_test() {
  let #(initial, _) = app.init(Nil)
  let #(reverse, _) = app.update(initial, app.SpeedChanged("-3"))
  assert reverse.speed == -3.0
  assert reverse.shape_slider == initial.shape_slider
  assert reverse.source == initial.source
  assert reverse.library == initial.library

  let #(fast, _) = app.update(reverse, app.SpeedChanged("3"))
  assert fast.speed == 3.0
  assert fast.shape_slider == initial.shape_slider
  assert fast.source == initial.source
  assert fast.library == initial.library
}

pub fn shape_slider_changes_shape_without_changing_speed_test() {
  let #(initial, _) = app.init(Nil)
  let #(moving, _) = app.update(initial, app.SpeedChanged("-1.5"))
  let #(shaped, _) = app.update(moving, app.ShapeChanged("25"))
  assert shaped.shape_slider == 25
  assert shaped.speed == -1.5
  assert shaped.source == moving.source
  assert shaped.library == moving.library
}

pub fn drawings_keep_independent_valid_and_invalid_source_test() {
  let square_edit = "this is intentionally invalid square source"
  let fan_edit = "fn draw(shape_slider: Int) -> List(Path) { [] } // fan edit"
  let #(initial, _) = app.init(Nil)
  let #(square, _) = app.update(initial, app.DrawingChanged("square_spiral"))
  let #(edited_square, _) =
    app.update(square, app.SetCode("square_spiral", square_edit))
  let #(fan, _) = app.update(edited_square, app.DrawingChanged("fan"))
  let #(edited_fan, _) = app.update(fan, app.SetCode("fan", fan_edit))
  // A queued callback from the old editor must update its own drawing while
  // leaving the newly selected drawing's editor source alone.
  let late_square_edit = "late square edit remains attached to square_spiral"
  let #(after_late_edit, _) =
    app.update(edited_fan, app.SetCode("square_spiral", late_square_edit))
  assert after_late_edit.selected == "fan"
  assert after_late_edit.source == fan_edit
  assert list.key_find(after_late_edit.library, "square_spiral")
    == Ok(late_square_edit)
  assert list.key_find(after_late_edit.library, "fan") == Ok(fan_edit)

  let #(reopened_square, _) =
    app.update(after_late_edit, app.DrawingChanged("square_spiral"))
  assert reopened_square.source == late_square_edit
  let #(reopened_fan, _) =
    app.update(reopened_square, app.DrawingChanged("fan"))
  assert reopened_fan.source == fan_edit
}
