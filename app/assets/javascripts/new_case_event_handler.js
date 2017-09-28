// Filters the components options by case category
$(function() {
  function strip_id_from_class(obj) {
    class_string = obj.className
    if(!class_string) { return null; } // Handles missing class name
    tag_without_id = class_string.match(/.*-id-/)[0]
    return parseInt(class_string.replace(tag_without_id, ''))
  }

  function new_case_update_component_field() {
    options = $('#CaseForm_case_component_id').children()
    categories = $('#CaseForm_case_case_category_id')
    selected_category_index = parseInt(categories.val()) -1
    selected_category = categories.children()[selected_category_index]

    // Unhides all the options fields
    options.each(function(_index, opt) { $(opt).show() })

    // Hide options that do not match the new case category
    options.filter(function(_index, opt) {
      selected_category_id = strip_id_from_class(selected_category)
      console.log(selected_category_id)
      return selected_category_id != strip_id_from_class(opt)
    }).each(function(_index, opt){ $(opt).hide() })
  }

  // Applies the event handler and runs it on load
  $('#CaseForm_case_case_category_id').change(function(){
    new_case_update_component_field()
  })
  new_case_update_component_field()
})
