import { Result$Ok, Result$Error } from "./gleam.mjs";
import { List$Empty, toList } from "./gleam.mjs";

const memoryStorage = new Map();

function browserStorage(name) {
  try {
    if (typeof window === "undefined") return null;
    return window[name] ?? null;
  } catch {
    return null;
  }
}

export function storageGet(key) {
  const persistent = browserStorage("localStorage");

  try {
    if (persistent) {
      const value = persistent.getItem(key);
      if (value !== null) return Result$Ok(value);
    }
  } catch (error) {
    console.warn("Could not read localStorage:", error);
  }

  const session = browserStorage("sessionStorage");

  try {
    if (session) {
      const value = session.getItem(key);
      if (value !== null) return Result$Ok(value);
    }
  } catch (error) {
    console.warn("Could not read sessionStorage:", error);
  }

  if (memoryStorage.has(key)) {
    return Result$Ok(memoryStorage.get(key));
  }

  return Result$Error(undefined);
}

export function storageSet(key, value) {
  let saved = false;

  const persistent = browserStorage("localStorage");

  try {
    if (persistent) {
      persistent.setItem(key, value);
      saved = true;
    }
  } catch (error) {
    console.warn("Could not save to localStorage:", error);
  }

  const session = browserStorage("sessionStorage");

  if (!saved) {
    try {
      if (session) {
        session.setItem(key, value);
        saved = true;
      }
    } catch (error) {
      console.warn("Could not save to sessionStorage:", error);
    }
  }

  // Last-resort fallback for restricted environments and test runners.
  if (!saved) {
    memoryStorage.set(key, value);
  }
}

export function promptDrawingName() {
  if (typeof window === "undefined") return "";
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
    return toList(pairs, List$Empty());
  } catch {
    return List$Empty();
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
