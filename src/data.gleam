//// The library of saved drawings. A drawing is a name and the source of its draw
//// function.

// ── localStorage (data_ffi.mjs) ───────────────────────────────────────────────

/// The string stored in localStorage under key, or an Error if there isn't one.
@external(javascript, "./data_ffi.mjs", "storageGet")
pub fn storage_get(key: String) -> Result(String, Nil)

/// Store value in localStorage under key, replacing anything already there. If that
/// isn't possible, this logs the reason to the browser console.
@external(javascript, "./data_ffi.mjs", "storageSet")
pub fn storage_set(key: String, value: String) -> Nil

// ── The new-drawing prompt (data_ffi.mjs) ─────────────────────────────────────

/// Prompt the user to name a new drawing; "" (empty string) means they
/// cancelled or left it blank.
@external(javascript, "./data_ffi.mjs", "promptDrawingName")
pub fn prompt_drawing_name() -> String

/// Load saved drawing pairs from browser storage. Malformed data is ignored.
@external(javascript, "./data_ffi.mjs", "loadDrawings")
pub fn load_drawings() -> List(#(String, String))

/// Persist the drawing library and selected name.
@external(javascript, "./data_ffi.mjs", "saveDrawings")
pub fn save_drawings(drawings: List(#(String, String)), selected: String) -> Nil

/// Restore the saved selection, or return an empty string when unavailable.
@external(javascript, "./data_ffi.mjs", "loadSelected")
pub fn load_selected() -> String
