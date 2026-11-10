//// Animator -- an application for program-generated drawings.

import builtins
import data
import drawing
import editor
import errors
import examples
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import lustre
import lustre/attribute as attr
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import parser
import render
import shape.{type Path}

/// Your app's public address, once deployed.
pub const public_url = "https://justinobomeghie.github.io/animator/"

pub const include_app_in_gallery = False

/// A link to your video from Problem 14.
pub const video_url = ""

pub const include_video_in_gallery = False

const library_key = "animator-drawings"

const selected_key = "animator-selected"

type Drawing =
  #(String, String)

pub type Model {
  Model(
    source: String,
    code_open: Bool,
    output: String,
    drawings: List(Drawing),
    selected: String,
    shape_slider: Int,
    speed: Int,
  )
}

pub type Msg {
  SetCode(String)
  ToggleCode
  ShapeChanged(String)
  SpeedChanged(String)
  SelectDrawing(String)
  NewDrawing
}

fn stored_drawing_decoder() -> decode.Decoder(Drawing) {
  use name <- decode.field("name", decode.string)
  use source <- decode.field("source", decode.string)
  decode.success(#(name, source))
}

fn library_decoder() -> decode.Decoder(List(Drawing)) {
  decode.list(stored_drawing_decoder())
}

fn encode_library(drawings: List(Drawing)) -> String {
  json.array(drawings, fn(drawing) {
    case drawing {
      #(name, source) ->
        json.object([
          #("name", json.string(name)),
          #("source", json.string(source)),
        ])
    }
  })
  |> json.to_string
}

fn save_library(drawings: List(Drawing), selected: String) -> Nil {
  data.storage_set(library_key, encode_library(drawings))
  data.storage_set(selected_key, selected)
}

fn first_name(drawings: List(Drawing)) -> String {
  case drawings {
    [#(name, _), ..] -> name
    [] -> "fan"
  }
}

fn source_for(drawings: List(Drawing), selected: String) -> String {
  case drawings {
    [#(name, source), ..rest] ->
      case name == selected {
        True -> source
        False -> source_for(rest, selected)
      }
    [] -> ""
  }
}

fn has_drawing(drawings: List(Drawing), selected: String) -> Bool {
  case drawings {
    [#(name, _), ..rest] -> name == selected || has_drawing(rest, selected)
    [] -> False
  }
}

fn replace_drawing(
  drawings: List(Drawing),
  selected: String,
  source: String,
) -> List(Drawing) {
  case drawings {
    [#(name, old_source), ..rest] ->
      case name == selected {
        True -> [#(name, source), ..rest]
        False -> [
          #(name, old_source),
          ..replace_drawing(rest, selected, source)
        ]
      }
    [] -> [#(selected, source)]
  }
}

pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let drawings = case data.storage_get(library_key) {
    Ok(saved) ->
      case json.parse(from: saved, using: library_decoder()) {
        Ok(restored) if restored != [] -> restored
        _ -> examples.all
      }
    Error(_) -> examples.all
  }

  let saved_selection = case data.storage_get(selected_key) {
    Ok(name) -> name
    Error(_) -> first_name(drawings)
  }

  let selected = case has_drawing(drawings, saved_selection) {
    True -> saved_selection
    False -> first_name(drawings)
  }

  let source = source_for(drawings, selected)
  save_library(drawings, selected)

  #(
    Model(
      source: source,
      code_open: True,
      output: "",
      drawings: drawings,
      selected: selected,
      shape_slider: 10,
      speed: 1,
    ),
    effect.batch([
      editor.mount(source, SetCode),
      effect.from(fn(dispatch) { dispatch(SetCode(source)) }),
    ]),
  )
}

fn run_source(shape_slider: Int, source: String) -> Result(List(Path), String) {
  case parser.parse_program(source, builtins.global_frame()) {
    Error(msg) -> Error(msg)
    Ok(program) ->
      drawing.try_draw(shape_slider, program)
      |> result.map_error(errors.error_message)
  }
}

fn speed_as_float(speed: Int) -> Float {
  case speed {
    -2 -> -2.0
    -1 -> -1.0
    0 -> 0.0
    1 -> 1.0
    _ -> 2.0
  }
}

fn update_drawing(model: Model, source: String) -> Model {
  let drawings = replace_drawing(model.drawings, model.selected, source)
  save_library(drawings, model.selected)
  Model(..model, source: source, drawings: drawings)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ToggleCode -> #(Model(..model, code_open: !model.code_open), effect.none())

    SetCode(source) -> {
      let model = update_drawing(model, source)
      case run_source(model.shape_slider, source) {
        Ok(paths) -> {
          let rendered =
            list.map(paths, fn(path) { render.render_path(path, "#d4c5a0") })
          render.set_drawing(rendered)
          #(Model(..model, output: ""), effect.none())
        }
        Error(message) -> {
          render.set_drawing([])
          #(Model(..model, output: message), effect.none())
        }
      }
    }

    ShapeChanged(value) ->
      case int.parse(value) {
        Ok(shape_slider) -> {
          let model = Model(..model, shape_slider: shape_slider)
          case run_source(shape_slider, model.source) {
            Ok(paths) -> {
              render.set_drawing(
                list.map(paths, fn(path) { render.render_path(path, "#d4c5a0") }),
              )
              #(Model(..model, output: ""), effect.none())
            }
            Error(message) -> {
              render.set_drawing([])
              #(Model(..model, output: message), effect.none())
            }
          }
        }
        Error(_) -> #(model, effect.none())
      }

    SpeedChanged(value) ->
      case int.parse(value) {
        Ok(speed) -> {
          render.set_speed(speed_as_float(speed))
          #(Model(..model, speed: speed), effect.none())
        }
        Error(_) -> #(model, effect.none())
      }

    SelectDrawing(name) -> {
      let source = source_for(model.drawings, name)
      save_library(model.drawings, name)
      let model = Model(..model, selected: name, source: source)
      #(
        model,
        effect.batch([
          editor.mount(source, SetCode),
          effect.from(fn(dispatch) { dispatch(SetCode(source)) }),
        ]),
      )
    }

    NewDrawing -> {
      let name = data.prompt_drawing_name()
      case name == "" || has_drawing(model.drawings, name) {
        True -> #(model, effect.none())
        False -> {
          let source = source_for(examples.all, first_name(examples.all))
          let drawings = list.append(model.drawings, [#(name, source)])
          save_library(drawings, name)
          let model =
            Model(
              ..model,
              drawings: drawings,
              selected: name,
              source: source,
              output: "",
            )
          #(
            model,
            effect.batch([
              editor.mount(source, SetCode),
              effect.from(fn(dispatch) { dispatch(SetCode(source)) }),
            ]),
          )
        }
      }
    }
  }
}

pub fn view(model: Model) -> Element(Msg) {
  let app_class = case model.code_open {
    True -> "app"
    False -> "app code-hidden"
  }

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
    html.div([attr.class("controls")], [
      html.div([attr.class("control-group")], [
        html.span([], [html.text("Drawing")]),
        html.select(
          [
            attr.attribute("data-test-id", "drawing-select"),
            attr.attribute("value", model.selected),
            event.on_change(SelectDrawing),
          ],
          list.map(model.drawings, fn(drawing) {
            case drawing {
              #(name, _) -> html.option([attr.attribute("value", name)], name)
            }
          }),
        ),
        html.button([attr.class("icon-btn"), event.on_click(NewDrawing)], [
          html.text("+ New"),
        ]),
      ]),
      html.div([attr.class("control-group")], [
        html.span([], [html.text("Shape")]),
        html.input([
          attr.attribute("type", "range"),
          attr.attribute("min", "0"),
          attr.attribute("max", "100"),
          attr.attribute("step", "1"),
          attr.attribute("value", int.to_string(model.shape_slider)),
          attr.attribute("data-test-id", "shape-slider"),
          event.on_input(ShapeChanged),
        ]),
        html.span([], [html.text(int.to_string(model.shape_slider))]),
      ]),
      html.div([attr.class("control-group")], [
        html.span([], [html.text("Speed")]),
        html.input([
          attr.attribute("type", "range"),
          attr.attribute("min", "-2"),
          attr.attribute("max", "2"),
          attr.attribute("step", "1"),
          attr.attribute("value", int.to_string(model.speed)),
          attr.attribute("data-test-id", "speed-slider"),
          event.on_input(SpeedChanged),
        ]),
        html.span([], [html.text(int.to_string(model.speed))]),
      ]),
    ]),
    html.canvas([attr.id("animation-canvas"), attr.class("canvas")]),
    html.pre([attr.class("output")], [html.text(model.output)]),
  ])
}

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

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
