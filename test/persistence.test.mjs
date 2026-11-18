import assert from "node:assert/strict";
import { test } from "node:test";

class MemoryStorage {
  #values = new Map();
  getItem(key) { return this.#values.get(key) ?? null; }
  setItem(key, value) { this.#values.set(key, String(value)); }
}

const localStorage = new MemoryStorage();
Object.defineProperty(globalThis, "localStorage", { value: localStorage, configurable: true });
globalThis.window = { localStorage };

const app = await import("../build/dev/javascript/animator/app.mjs");

function runPersistenceTask(effect) {
  const tasks = Array.from(effect.synchronous);
  assert.ok(tasks.length > 0, "expected a persistence task");
  // Lustre batches effects in reverse order; persistence is first in this app's
  // drawing-change batches.
  tasks[0]({ dispatch() {} });
}

test("reload restores the selected drawing and independent valid or invalid edits", () => {
  const originalSquare = "fn draw(shape_slider: Int) -> List(Path) { [] }";
  const originalFan = "fn draw(shape_slider: Int) -> List(Path) { [] } // original fan";
  localStorage.setItem("animator.drawings.v1", JSON.stringify([
    ["square_spiral", originalSquare],
    ["fan", originalFan],
  ]));
  localStorage.setItem("animator.selected.v1", "square_spiral");

  let [model] = app.init(undefined);
  assert.equal(model.selected, "square_spiral");
  assert.equal(model.source, originalSquare);

  const invalidSquare = "this deliberately does not parse: [";
  let [updated, squareEditEffect] = app.update(model, new app.SetCode("square_spiral", invalidSquare));
  runPersistenceTask(squareEditEffect);

  let [fan, fanSelectionEffect] = app.update(updated, new app.DrawingChanged("fan"));
  runPersistenceTask(fanSelectionEffect);
  const editedFan = "fn draw(shape_slider: Int) -> List(Path) { [] } // edited fan";
  let [editedFanModel, fanEffect] = app.update(fan, new app.SetCode("fan", editedFan));
  runPersistenceTask(fanEffect);

  // Simulate a full page reload: a fresh init reads only the persisted store.
  let [restored] = app.init(undefined);
  assert.equal(restored.selected, "fan");
  assert.equal(restored.source, editedFan);

  let [restoredSquare, squareEffect] = app.update(restored, new app.DrawingChanged("square_spiral"));
  runPersistenceTask(squareEffect);
  assert.equal(restoredSquare.source, invalidSquare);

  let [restoredFan] = app.update(restoredSquare, new app.DrawingChanged("fan"));
  assert.equal(restoredFan.source, editedFan);
  assert.equal(editedFanModel.source, editedFan);
});
