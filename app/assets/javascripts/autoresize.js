function enableAutoResize() {
  autosize(document.querySelector('textarea'))
}

document.addEventListener('turbolinks:load', enableAutoResize);
