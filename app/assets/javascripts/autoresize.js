function enableAutoResize() {
  $('textarea').autoresize();
}

document.addEventListener('turbolinks:load', enableAutoResize);
