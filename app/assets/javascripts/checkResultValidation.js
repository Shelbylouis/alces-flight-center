var scrollScript = document.createElement('script');
scrollScript.setAttribute(
  'src',
  '//cdnjs.cloudflare.com/ajax/libs/jquery-scrollTo/2.1.2/jquery.scrollTo.min.js'
);
document.head.appendChild(scrollScript)

var validateScript = document.createElement('script');
validateScript.setAttribute(
  'src',
  'https://ajax.aspnetcdn.com/ajax/jquery.validate/1.9/jquery.validate.min.js'
);
document.head.appendChild(validateScript)

function validationScrolling() {
  $("#check-result-submission-form").validate({
    focusInvalid: false,
    invalidHandler: function(form, validator) {
      if (!validator.numberOfInvalids())
        return;

      $('html, body').animate({
        scrollTop: $(validator.errorList[0].element).offset().top-200
      });
    }
  });
}

document.addEventListener('turbolinks:load', validationScrolling);
