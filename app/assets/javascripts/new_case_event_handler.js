// Filters the components options by case category
$(function() {

  function data_attr_id(obj, data_tag) {
    return $(obj).attr('data-' + data_tag + '-id')
  }

  function options() { return $('#CaseForm_case_component_id').children() }
  function categories() { return $('#CaseForm_case_case_category_id') }
  function selected_category() {
    index = parseInt(categories().val()) -1
    return categories().children()[index]
  }

  function show_all_components() {
    options().each(function(_index, opt) { $(opt).show() })
  }

  function filter_components_on_selected_case_category() {
    selected_component_type_id = data_attr_id(selected_category(), 'component-type')

    // Hides components that do not match the select component type
    if(selected_component_type_id) {
      options().filter(function(_index, opt) {
        return selected_component_type_id != data_attr_id(opt, 'component-type')
      }).each(function(_index, opt){ $(opt).hide() })
    }
  }

  function event_handler() {
    show_all_components()
    filter_components_on_selected_case_category()
  }

  // Applies the event handler and runs it on load
  $('#CaseForm_new_case').change(function(){ event_handler() })
  event_handler()
})
