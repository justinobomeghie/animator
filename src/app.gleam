//// Animator -- an application for program-generated drawings.

import builtins
import drawing
import data
import examples
import editor
import errors
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre
import lustre/attribute as attr
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import parser
import render
import shape.{type Path}

/// Your app's public address, once you've deployed it in Problem 13, such as
/// "https://your-username.github.io/animator/".
pub const public_url = "https://justinobomeghie.github.io/animator/"

/// Set to True if you would like your app's URL included in the course gallery.
pub const include_app_in_gallery = False

/// A link to your video from Problem 14, which anyone with the link can watch.
pub const video_url = ""

/// Set to True if you would like your video included in the course gallery.
pub const include_video_in_gallery = False

const default_code = "fn draw(shape_slider: Int) -> List(Path) {\n  [Path(Line(Point(0, 0), Point(100, 100)), 0, 10, 2)]\n}\n"

// ── Model ──────────────────────────────────────────────────────────────────────

pub type Model {
  Model(
    // The code in the editor.
    source: String,
    // Whether the code editor is shown.
    code_open: Bool,
    output: String,
    shape_slider: Int,
    speed: Float,
    selected: String,
    library: List(#(String, String)),
  )
}

pub type Msg {
  SetCode(String)

  // Layout controls
  ToggleCode
  ShapeChanged(String)
  SpeedChanged(String)
  DrawingChanged(String)
  NewDrawing
  Play
  Pause
  Reset
}

// ── Init ───────────────────────────────────────────────────────────────────────

pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let saved = data.load_drawings()
  let library = merge_library(examples.all, saved)
  let saved_selection = data.load_selected()
  let selected_name = case saved_selection == "storybook_squirrel" {
    True -> "storybook_flower"
    False -> saved_selection
  }
  let selected = case list.key_find(library, selected_name) {
    Ok(_) -> selected_name
    Error(Nil) -> "storybook_flower"
  }
  let source = source_for(selected, library)
  #(
    Model(source:, code_open: True, output: "", shape_slider: 50, speed: 1.0, selected:, library:),
    // Effects that happen automatically at the start go here.
    effect.batch([
      editor.mount(source, SetCode),
      effect.from(fn(dispatch) { dispatch(SetCode(source)) }),
    ]),
  )
}

// Keep bundled examples current while preserving user-edited sources and custom
// drawings. Migrate the retired squirrel selection to the new flower example.
fn merge_library(
  defaults: List(#(String, String)),
  saved: List(#(String, String)),
) -> List(#(String, String)) {
  let bundled = list.map(defaults, fn(default) {
    case list.key_find(saved, default.0) {
      Error(Nil) -> default
      Ok(source) -> {
        #(default.0, source)
      }
    }
  })
  let custom = list.filter(saved, fn(drawing) {
    drawing.0 != "storybook_squirrel"
      && !list.any(defaults, fn(default) { default.0 == drawing.0 })
  })
  list.append(bundled, custom)
}

fn source_for(name: String, library: List(#(String, String))) -> String {
  case list.key_find(library, name) {
    Ok(source) -> source
    Error(Nil) -> default_code
  }
}

// Parse and evaluate a draw function at the given shape-slider value, returning
// the rendered paths on success, or a human-readable message on failure.
fn run_source(shape_slider: Int, source: String) -> Result(List(Path), String) {
  case parser.parse_program(source, builtins.global_frame()) {
    Error(msg) -> Error(msg)
    Ok(program) ->
      drawing.try_draw(shape_slider, program)
      // Convert Error(EvalError) to Error(String) with a useful error message.
      |> result.map_error(errors.error_message)
  }
}

// ── Update ─────────────────────────────────────────────────────────────────────

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ToggleCode -> #(Model(..model, code_open: !model.code_open), effect.none())

    ShapeChanged(value) -> {
      let slider = result.unwrap(int.parse(value), model.shape_slider)
      let next = Model(..model, shape_slider: slider)
      #(next, draw_effect(next))
    }
    SpeedChanged(value) -> {
      let speed = result.unwrap(float.parse(value), model.speed)
      #(Model(..model, speed:), effect.from(fn(_) { render.set_speed(speed) }))
    }
    Play -> #(model, effect.from(fn(_) { render.set_speed(model.speed) }))
    Pause -> #(model, effect.from(fn(_) { render.set_speed(0.0) }))
    Reset -> #(model, effect.from(fn(_) { render.reset_clock() }))
    DrawingChanged(name) -> {
      let source = source_for(name, model.library)
      let next = Model(..model, selected: name, source:)
      #(next, effect.batch([editor.mount(source, SetCode), draw_effect(next), persist(next)]))
    }
    NewDrawing -> {
      let name = string.trim(data.prompt_drawing_name())
      case name == "" || list.contains(list.map(model.library, fn(d) { d.0 }), name) {
        True -> #(model, effect.none())
        False -> {
          let library = list.append(model.library, [#(name, default_code)])
          let next = Model(..model, library:, selected: name, source: default_code)
          #(next, effect.batch([editor.mount(default_code, SetCode), draw_effect(next), persist(next)]))
        }
      }
    }

    // After each keystroke in the editor, evaluate user code and report errors.
    SetCode(text) ->
      case run_source(model.shape_slider, text) {
        // Parsed and evaluated: show the result.
        Ok(paths) -> #(
          Model(..model, output: "", source: text, library: list.map(model.library, fn(d) { case d.0 == model.selected { True -> #(d.0, text) False -> d } })),
          effect.batch([effect.from(fn(_) {
            render.set_drawing(paths_for_canvas(paths, model.selected))
            render.set_speed(model.speed)
            render.set_looping(model.selected == "storybook_flower")
          }), persist(Model(..model, source: text, library: list.map(model.library, fn(d) { case d.0 == model.selected { True -> #(d.0, text) False -> d } })))]),
        )
        // Broken (parse or evaluation): show the error.
        Error(msg) -> #(
          Model(..model, output: msg, source: text),
          effect.none(),
        )
      }
  }
}

fn persist(model: Model) -> Effect(Msg) {
  effect.from(fn(_) { data.save_drawings(model.library, model.selected) })
}

fn draw_effect(model: Model) -> Effect(Msg) {
  case run_source(model.shape_slider, model.source) {
    Ok(paths) -> effect.from(fn(_) {
      render.reset_clock()
      render.set_drawing(paths_for_canvas(paths, model.selected))
      render.set_speed(model.speed)
      render.set_looping(model.selected == "storybook_flower")
    })
    Error(_) -> effect.from(fn(_) {
      render.set_drawing([])
      render.set_looping(False)
    })
  }
}

fn paths_for_canvas(paths: List(Path), selected: String) -> List(render.RenderPath) {
  case selected == "storybook_flower" {
    True -> list.map(paths, render.render_flower_path)
    False -> list.map(paths, render.render_path(_, "#D98FA9"))
  }
}

// ── View ──────────────────────────────────────────────────────────────────
//
// Two side-by-side panes: the code editor on the left and its rendered output on
// the right. The code column can be hidden to expand the right pane.

pub fn view(model: Model) -> Element(Msg) {
  let app_class = case model.code_open {
    True -> "app"
    False -> "app code-hidden"
  }
  // The code column still exists even when hidden (CSS collapses it) so the
  // mounted CodeMirror editor keeps its state across show/hide.
  html.div([attr.class(app_class)], [
    html.div([attr.class("code-col")], [
      editor.view_panel(ToggleCode),
    ]),
    view_anim(model),
  ])
}

fn view_anim(model: Model) -> Element(Msg) {
  html.div([attr.class("canvas-area")], [
    view_reveal_code(model),
    html.div([attr.class("studio-controls")], [
      html.select([attr.value(model.selected), attr.attribute("data-test-id", "drawing-select"), event.on_change(DrawingChanged)], list.map(model.library, fn(d) { html.option([attr.value(d.0)], d.0) })),
      html.button([event.on_click(NewDrawing)], [html.text("New drawing")]),
      html.label([], [html.text("Shape"), html.span([attr.class("control-value")], [html.text(int.to_string(model.shape_slider))]), html.input([attr.type_("range"), attr.attribute("min", "0"), attr.attribute("max", "100"), attr.value(int.to_string(model.shape_slider)), attr.attribute("data-test-id", "shape-slider"), event.on_input(ShapeChanged)])]),
      html.label([], [html.text("Speed"), html.span([attr.class("control-value")], [html.text(float.to_string(model.speed) <> "×")]), html.input([attr.type_("range"), attr.attribute("min", "-3"), attr.attribute("max", "3"), attr.attribute("step", "0.1"), attr.value(float.to_string(model.speed)), attr.attribute("data-test-id", "speed-slider"), event.on_input(SpeedChanged)])]),
      html.button([event.on_click(Play)], [html.text("Play")]),
      html.button([event.on_click(Pause)], [html.text("Pause")]),
      html.button([event.on_click(Reset)], [html.text("Reset")]),
    ]),
    html.canvas([attr.id("animation-canvas"), attr.class("canvas")]),
    html.pre([attr.class("output")], [html.text(model.output)]),
  ])
}

// The button that brings the code column back, overlaid on the top-left of the
// right pane. Nothing is rendered while the column is already showing (its own
// header holds the button that hides it).
fn view_reveal_code(model: Model) -> Element(Msg) {
  case model.code_open {
    True -> element.none()
    False ->
      html.button(
        [
          attr.class("icon-btn reveal-code"),
          attr.attribute("title", "Show code"),
          event.on_click(ToggleCode),
        ],
        [html.text("⟩")],
      )
  }
}

// ── Main ───────────────────────────────────────────────────────────────────────

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
