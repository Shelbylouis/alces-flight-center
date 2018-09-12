function enableAutoResize() {
  document.querySelectorAll('textarea').forEach(function(ta){
    autosize(ta)
  });
}

document.addEventListener('turbolinks:load', enableAutoResize);
