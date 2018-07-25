function showPreview(event, editor) {
  event.preventDefault();
  $.ajax({
    url: event.target.getAttribute('data-preview-url'),
    method: 'POST',
    data: getData(editor),
  })
    .then((content) => {
      editor.html(content);
      configureMarkdownPreview();
    });
}

function showWrite(event, editor) {
  event.preventDefault();
  $.ajax({
    url: event.target.getAttribute('data-write-url'),
    method: 'POST',
    data: getData(editor),
  })
    .then((content) => {
      editor.html(content);
      configureMarkdownPreview();
    });
}

function getData(editor) {
  const contentElement = editor.find($('[data-markdown-content]'))[0]
  return {
      authenticity_token: window._authenticity_token,
      [contentElement.name]: contentElement.value,
  }
}

function configureMarkdownPreview() {
  const editor = $('[data-markdown-editor]');
  editor.each(function(e){
    $(this).find('[data-markdown-preview-button]').click((e) => showPreview(e, $(this)));
    $(this).find('[data-markdown-write-button]').click((e) => showWrite(e, $(this)));
  })
};

document.addEventListener('turbolinks:load', configureMarkdownPreview);
