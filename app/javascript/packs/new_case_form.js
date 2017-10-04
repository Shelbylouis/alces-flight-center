
import Elm from './Main'


document.addEventListener('DOMContentLoaded', () => {
  const target = document.getElementById('new-case-form')

  const loadAttributeJson =
    attribute => JSON.parse(target.getAttribute(attribute))

  const flags = {
    clusters: loadAttributeJson('data-clusters'),
    caseCategories: loadAttributeJson('data-case-categories'),
    components: loadAttributeJson('data-components'),
  }

  Elm.Main.embed(target, flags)
})
