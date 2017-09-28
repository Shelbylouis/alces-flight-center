// Filters the components options by case category
$(function() {
  function new_case_update_component_field() {
    var new_case_category = $('#CaseForm_case_case_category_id').val()
    options = $('#CaseForm_case_component_id').children()

    // Unhides all the options fields
    options.each(function(_index, opt) { $(opt).show() })

    // Hide options that do not match the new case category
    options.filter(function(_index, opt) {
      option_case_category_id = opt.className.replace('data-component-type-id-', '')
      return new_case_category != option_case_category_id
    }).each(function(_index, opt){ $(opt).hide() })
  }

  // Applies the event handler and runs it on load
  $('#CaseForm_case_case_category_id').change(function(){
    new_case_update_component_field()
  })
  new_case_update_component_field()
})
