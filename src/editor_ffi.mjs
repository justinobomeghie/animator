let cmModulePromise = null;

function loadCodeMirror(target_element, initial_code, onChange) {
  if (cmModulePromise) {
    return cmModulePromise.then((modules) =>
      initEditorWithModules(modules, target_element, initial_code, onChange)
    );
  }

  const V = "6";
  cmModulePromise = Promise.all([
    import(/* @vite-ignore */ `https://esm.sh/@codemirror/view@${V}`),
    import(/* @vite-ignore */ `https://esm.sh/@codemirror/state@${V}`),
    import(/* @vite-ignore */ `https://esm.sh/@codemirror/commands@${V}`),
    import(/* @vite-ignore */ `https://esm.sh/@codemirror/language@${V}`),
    import(/* @vite-ignore */ `https://esm.sh/@codemirror/autocomplete@${V}`),
    import(/* @vite-ignore */ `https://esm.sh/@lezer/highlight@1`),
  ]);

  return cmModulePromise.then((modules) =>
    initEditorWithModules(modules, target_element, initial_code, onChange)
  );
}

function initEditorWithModules([view, state, commands, language, autocomplete, highlight], target_element, initial_code, onChange) {
  const updateListener = view.EditorView.updateListener.of((update) => {
    if (update.docChanged) {
      onChange(update.state.doc.toString());
    }
  });

  const editorState = state.EditorState.create({
    doc: initial_code,
    extensions: [
      view.keymap.of([...commands.defaultKeymap, ...autocomplete.completionKeymap]),
      view.lineNumbers(),
      view.highlightActiveLineGutter(),
      view.highlightSpecialChars(),
      commands.history(),
      view.drawSelection(),
      state.EditorState.allowMultipleSelections.of(true),
      language.indentOnInput(),
      view.highlightActiveLine(),
      updateListener,
    ],
  });

  return new view.EditorView({
    state: editorState,
    parent: target_element,
  });
}

export function mountEditor(target_element, initial_code, onChange) {
  return loadCodeMirror(target_element, initial_code, onChange);
}

export function init_editor(target_element, initial_code, onChange) {
  return loadCodeMirror(target_element, initial_code, onChange);
}
