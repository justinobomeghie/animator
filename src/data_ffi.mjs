// The browser features behind data.gleam.

import { Result$Ok, Result$Error } from "./gleam.mjs";
import { List$Empty$const, toList } from "./gleam.mjs";

// localStorage can throw: when the browser blocks it for this site, or (on a
// write) when the site is out of space.
export function storageGet(key) {
  try {
    const value = globalThis.localStorage.getItem(key);
    return value === null ? Result$Error(undefined) : Result$Ok(value);
  } catch {
    return Result$Error(undefined);
  }
}

export function storageSet(key, value) {
  try {
    globalThis.localStorage.setItem(key, value);
  } catch (error) {
    console.error(`Couldn't save: ${error.message}`);
  }
}

// Ask the user to name a new drawing; "" (empty string) means they cancelled.
export function promptDrawingName() {
  const name = window.prompt("Name for the new drawing:");
  return name === null ? "" : name;
}

const DRAWINGS_KEY = "animator.drawings.v1";
const SELECTED_KEY = "animator.selected.v1";

export function loadDrawings() {
  try {
    const raw = globalThis.localStorage.getItem(DRAWINGS_KEY);
    const parsed = raw === null ? [] : JSON.parse(raw);
    if (!Array.isArray(parsed)) return List$Empty$const;
    const pairs = parsed.filter((item) => Array.isArray(item)
      && item.length === 2
      && typeof item[0] === "string"
      && typeof item[1] === "string");
    return toList(pairs, List$Empty$const);
  } catch {
    return List$Empty$const;
  }
}

export function saveDrawings(drawings, selected) {
  try {
    globalThis.localStorage.setItem(DRAWINGS_KEY, JSON.stringify(Array.from(drawings)));
    globalThis.localStorage.setItem(SELECTED_KEY, selected);
  } catch (error) {
    console.error(`Couldn't save drawings: ${error.message}`);
  }
}

export function loadSelected() {
  try { return globalThis.localStorage.getItem(SELECTED_KEY) ?? ""; }
  catch { return ""; }
}
