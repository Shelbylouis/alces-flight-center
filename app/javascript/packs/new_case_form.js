import Elm from 'Main';

const initializeFormApp = () => {
  const target = document.getElementById('new-case-form');

  // Only initialize the form app if the target exists (we're on a page
  // requiring the form) and has no children (indicates app has already been
  // initialized, e.g. this occurs due to Turbolinks if navigate away and then
  // back to page using browser back/forward buttons).
  if (target && !target.hasChildNodes()) {
    const loadAttributeJson = attribute =>
      JSON.parse(target.getAttribute(attribute));

    const flags = {
      clusters: loadAttributeJson('data-clusters'),
      singlePart: loadAttributeJson('data-single-part'),
      selectedTool: loadAttributeJson('data-selected-tool'),
    };

    Elm.Main.embed(target, flags);
  }
};

document.addEventListener('turbolinks:load', initializeFormApp);
