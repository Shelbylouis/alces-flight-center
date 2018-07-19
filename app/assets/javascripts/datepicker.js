function initialiseDatepicker() {
  $("#datepicker").datepicker({
    format: "yyyy-mm-dd",
    endDate: '+0d',
    daysOfWeekDisabled: [0,6],
    todayHighlight: true,
    todayBtn: "linked",
    orientation: "bottom"
  });
}

document.addEventListener('turbolinks:load', initialiseDatepicker);
