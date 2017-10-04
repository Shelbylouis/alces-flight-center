
import Elm from './Main'

document.addEventListener('DOMContentLoaded', () => {
  const target = document.getElementById('new-case-form')
  Elm.Main.embed(target)
})
