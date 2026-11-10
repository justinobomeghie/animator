#!/bin/bash
set -eu

echo "Starting Animator Phase 1 repair..."

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import sys

p = Path("src/evaluator.gleam")
e = Path("src/errors.gleam")

if not p.exists() or not e.exists():
    sys.exit("Project files not found.")

code = p.read_text()
errors = e.read_text()

if "NoMatchingCase" not in errors:
    sys.exit("NoMatchingCase is missing. No changes made.")

backup = p.with_name(
    "evaluator.gleam.backup." +
    datetime.now().strftime("%Y%m%d_%H%M%S")
)
shutil.copy2(p, backup)
print("Backup:", backup)

def replace(start, end, new, label):
    global code
    a = code.find(start)
    if a < 0:
        sys.exit("Could not find " + label)
    b = code.find(end, a + len(start))
    if b < 0:
        sys.exit("Could not find end of " + label)
    code = code[:a] + new + code[b:]
    print("Prepared:", label)

replace(
    "fn eval(expr: Expr, env: Env) -> Result(Value, EvalError) {",
    "/// Evaluate a list literal [a, b, ..rest].",
    """fn eval(expr: Expr, env: Env) -> Result(Value, EvalError) {
  limits.charge(1)
  case expr {
    Var(name) -> lookup(env, name)
    LiteralBool(b) -> Ok(VBool(b))
    LiteralInt(n) -> Ok(VInt(n))
    LiteralList(elems, rest) -> eval_list(elems, rest, env)
    Call(fn_expr, operands) ->
      case eval(fn_expr, env) {
        Error(e) -> Error(e)
        Ok(function) ->
          case list.try_map(operands, fn(operand) {
            eval(operand, env)
          }) {
            Error(e) -> Error(e)
            Ok(args) -> apply(function, args)
          }
      }
    Let(name, v, body) ->
      case eval(v, env) {
        Error(e) -> Error(e)
        Ok(value) -> eval(body, extend(env, [#(name, value)]))
      }
    Case(subject, arms) ->
      case eval(subject, env) {
        Error(e) -> Error(e)
        Ok(value) ->
          case find_arm(value, arms) {
            Ok(#(bindings, body)) ->
              eval(body, extend(env, bindings))
            Error(Nil) -> Error(errors.NoMatchingCase)
          }
      }
    Lambda(params, body) ->
      Ok(VFunc(UserFn("lambda", params, body, env)))
    FieldAccess(record, field) ->
      case eval(record, env) {
        Error(e) -> Error(e)
        Ok(v) -> get_field(v, field)
      }
    At(line, expr) ->
      result.map_error(eval(expr, env), errors.at_line(_, line))
  }
}

""",
    "expression evaluator"
)

replace(
    "fn eval_list(",
    "/// Apply a function value to already-evaluated arguments.",
    """fn eval_list(
  elems: List(Expr),
  rest: Option(Expr),
  env: Env,
) -> Result(Value, EvalError) {
  case list.try_map(elems, fn(e) { eval(e, env) }), rest {
    Error(e), _ -> Error(e)
    Ok(head), None -> Ok(VList(head))
    Ok(head), Some(r) ->
      case eval(r, env) {
        Ok(VList(tail)) -> Ok(VList(list.append(head, tail)))
        Ok(other) ->
          Error(TypeError("`..` expects a list, got " <> describe(other)))
        Error(e) -> Error(e)
      }
  }
}

""",
    "list literals"
)

replace(
    "pub fn apply(",
    "/// How many arguments a function takes.",
    """pub fn apply(f: Value, args: List(Value)) -> Result(Value, EvalError) {
  limits.charge(1)
  case f {
    VFunc(callable) -> {
      let wanted = num_params(callable)
      case list.length(args) == wanted {
        False ->
          Error(wrong_num_args(callable.name, wanted, list.length(args)))
        True ->
          case callable {
            Builtin(_, _, run) -> run(args)
            UserFn(_, params, body, parent) -> {
              let bindings = dict.from_list(list.zip(params, args))
              eval(body, Local(bindings, parent))
            }
          }
      }
    }
    _ -> Error(TypeError("calling a value that is not a function"))
  }
}

""",
    "function application"
)

replace(
    "pub fn lookup(",
    "// ── Pattern matching",
    """pub fn lookup(env: Env, name: String) -> Result(Value, EvalError) {
  case env {
    Local(bindings, parent) ->
      case dict.get(bindings, name) {
        Ok(value) -> Ok(value)
        Error(Nil) -> lookup(parent, name)
      }
    Global(bindings) ->
      case mutable_dict.get(bindings, name) {
        Ok(value) -> Ok(value)
        Error(Nil) -> Error(errors.UnboundVariable(name))
      }
  }
}

""",
    "variable lookup"
)

replace(
    "fn match_pattern(",
    "/// The names that the list pattern",
    """fn match_pattern(
  pattern: Pattern,
  value: Value,
) -> Result(List(#(String, Value)), Nil) {
  case pattern, value {
    PBool(b1), VBool(b2) if b1 == b2 -> Ok([])
    PInt(n1), VInt(n2) if n1 == n2 -> Ok([])
    PWildcard, _ -> Ok([])
    PVar(name), _ -> Ok([#(name, value)])
    PList(elems, rest), VList(vs) -> match_list(elems, rest, vs)
    _, _ -> Error(Nil)
  }
}

""",
    "variable patterns"
)

replace(
    "fn match_list(",
    "// ── Running a program",
    """fn match_list(
  elems: List(Pattern),
  rest: Option(String),
  vs: List(Value),
) -> Result(List(#(String, Value)), Nil) {
  case elems, rest, vs {
    [], None, [] -> Ok([])
    [], Some(x), _ -> Ok([#(x, VList(vs))])
    [pattern, ..patterns], rest, [value, ..values] ->
      case match_pattern(pattern, value),
           match_list(patterns, rest, values) {
        Ok(head), Ok(tail) -> Ok(list.append(head, tail))
        _, _ -> Error(Nil)
      }
    _, _, _ -> Error(Nil)
  }
}

""",
    "list patterns"
)

p.write_text(code)
print("All eight Phase 1 sections have been patched.")
print("Original file backed up.")
PY

echo ""
echo "Formatting..."
gleam format src/evaluator.gleam

echo ""
echo "Running complete test suite..."
gleam test

echo ""
echo "Repair script finished."
