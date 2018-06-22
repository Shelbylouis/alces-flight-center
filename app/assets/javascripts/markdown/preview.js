function showPreview(event) {
  event.preventDefault();
  $.ajax({
    url: event.target.getAttribute('data-preview-url'),
    method: 'POST',
    data: getData(),
  })
    .then((content) => {
      $('#markdown-editor').replaceWith(content);
      configureMarkdownPreview();
    });
}

function showWrite(event) {
  event.preventDefault();
  $.ajax({
    url: event.target.getAttribute('data-write-url'),
    method: 'POST',
    data: getData(),
  })
    .then((content) => {
      $('#markdown-editor').replaceWith(content);
      configureMarkdownPreview();
    });
}

function getData() {
  const contentElement = document.querySelector('[data-markdown-content]');
  return {
      authenticity_token: window._authenticity_token,
      [contentElement.name]: contentElement.value,
  }
}

function configureMarkdownPreview() {
  let target;
  target = document.getElementById('markdown-preview-button');
  if (target) {
    target.addEventListener('click', showPreview);
  }
  target = document.getElementById('markdown-write-button');
  if (target) {
    target.addEventListener('click', showWrite);
  }
};

document.addEventListener('turbolinks:load', configureMarkdownPreview);
