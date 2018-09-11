function showPreview(event, editor) {
  event.preventDefault();
  $.ajax({
    url: event.target.getAttribute('data-preview-url'),
    method: 'POST',
    data: getData(editor),
  })
    .then((content) => {
      editor.html(content);
      configureEditor(editor);
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
      configureEditor(editor);
    });
}

function getData(editor) {
  const contentElement = editor.find(('[data-markdown-content]'))[0]
  return {
      authenticity_token: window._authenticity_token,
      [contentElement.name]: contentElement.value,
  }
}

function configureMarkdownPreview() {
  const editor = $('[data-markdown-editor]');
  editor.each(function(e){
    configureEditor($(this))
  })
};

function configureEditor(editor) {
  editor.find('[data-markdown-preview-button]').click((e) => showPreview(e, editor));
  editor.find('[data-markdown-write-button]').click((e) => showWrite(e, editor));
  autosize(document.querySelector('textarea'))
};

document.addEventListener('turbolinks:load', configureMarkdownPreview);
