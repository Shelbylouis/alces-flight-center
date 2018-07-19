function initialiseDatepicker() {
  $("#datepicker").datepicker({
    format: "yyyy-mm-dd",
    endDate: '+0d',
    daysOfWeekDisabled: [0,6],
    daysOfWeekHighlighted: [1,2,3,4,5],
    todayHighlight: true,
    todayBtn: "linked",
    orientation: "bottom"
  });
}

document.addEventListener('turbolinks:load', initialiseDatepicker);
