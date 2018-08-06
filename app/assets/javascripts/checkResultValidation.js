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
