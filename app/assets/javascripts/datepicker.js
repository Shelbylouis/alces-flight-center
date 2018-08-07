function initialiseDatepicker() {
  // Having a datepicker defined for each use case separately isn't necessary
  // as there are methods you can call to handle changing the disabled days for
  // example. However for now this offers the ability for easier individual
  // customisation if we need it.

  $("#restricted-datepicker").datepicker({
    format: "yyyy-mm-dd",
    endDate: '+0d',
    daysOfWeekDisabled: [0,6],
    todayHighlight: true,
    todayBtn: "linked",
    orientation: "bottom"
  });

  $("#credit-datepicker").datepicker({
    format: "yyyy-mm-dd",
    endDate: '+0d',
    todayHighlight: true,
    todayBtn: "linked",
    orientation: "bottom"
  });

  $("#maintenance-datepicker").datepicker({
    format: "yyyy-mm-dd",
    todayHighlight: true,
    todayBtn: "linked",
    autoclose: true,
    orientation: "bottom"
  });
}

document.addEventListener('turbolinks:load', initialiseDatepicker);
