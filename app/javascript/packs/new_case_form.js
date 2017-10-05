
import Elm from './Main'

const initializeFormApp = () => {
  const target = document.getElementById('new-case-form')
  if (target) {
    const loadAttributeJson =
      attribute => JSON.parse(target.getAttribute(attribute))

    const flags = {
      clusters: loadAttributeJson('data-clusters'),
      caseCategories: loadAttributeJson('data-case-categories'),
      components: loadAttributeJson('data-components'),
    }

    Elm.Main.embed(target, flags)
  }
}

document.addEventListener('turbolinks:load', initializeFormApp)
