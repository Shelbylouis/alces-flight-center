const initializeConsultancyForm = () => {
  const $consultancyDetails = $('.consultancy-details');
  const $consultancySubmit = $('.consultancy-submit');

  const toggleSubmitButtonEnabled = () =>
    $consultancyDetails.val() === ''
      ? $consultancySubmit.prop('disabled', true)
      : $consultancySubmit.prop('disabled', false);

  // Toggle whether submit button should be enabled on page load and then every
  // key press.
  toggleSubmitButtonEnabled();
  $consultancyDetails.on('keyup', toggleSubmitButtonEnabled);
};

document.addEventListener('turbolinks:load', initializeConsultancyForm);
