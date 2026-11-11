// FFI bridge for CodeMirror integration
let cmModulePromise = null;

function loadCodeMirror(target_element, initial_code, onChange) {
  const V = "6";
  
  if (!cmModulePromise) {
    cmModulePromise = Promise.all([
      import(/* @vite-ignore */ `https://esm.sh/@codemirror/view@${V}`),
      import(/* @vite-ignore */ `https://esm.sh/@codemirror/state@${V}`),
      import(/* @vite-ignore */ `https://esm.sh/@codemirror/commands@${V}`),
      import(/* @vite-ignore */ `https://esm.sh/@codemirror/language@${V}`),
      import(/* @vite-ignore */ `https://esm.sh/@codemirror/autocomplete@${V}`),
      import(/* @vite-ignore */ `https://esm.sh/@lezer/highlight@1`),
    ]);
  }

  cmModulePromise.then(([view, state, commands, language, autocomplete, highlight]) => {
    const editorState = state.EditorState.create({
      doc: initial_code,
      extensions: [
        view.keymap.of(commands.defaultKeymap),
        view.EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            onChange(update.state.doc.toString());
          }
        }),
      ],
    });

    new view.EditorView({
      state: editorState,
      parent: target_element,
    });
  });
}

// Export both names to satisfy Gleam FFI bindings
export function mountEditor(target_element, initial_code, onChange) {
  return loadCodeMirror(target_element, initial_code, onChange);
}

export function init_editor(target_element, initial_code, onChange) {
  return loadCodeMirror(target_element, initial_code, onChange);
}
