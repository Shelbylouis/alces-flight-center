import Elm from 'Main';

const initializeFormApp = () => {
  const target = document.getElementById('new-case-form');

  // Only initialize the form app if the target exists, i.e. we're on a page
  // requiring the form.
  if (target) {
    // Clear any existing contents of the form root, e.g. if this page has been
    // reached via history navigation Turbolinks will have cached the last seen
    // version of the form, but without the corresponding JS (compiled Elm), so
    // we just want to completely replace this.
    target.innerHTML = '';

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
