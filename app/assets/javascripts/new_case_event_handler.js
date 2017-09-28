// Filters the components options by case category
$(function() {

  function data_attr_id(obj, data_tag) {
    return $(obj).attr('data-' + data_tag + '-id')
  }

  function options() { return $('#CaseForm_case_component_id').children() }

  function selected(object) {
    index = parseInt(object.val()) - 1
    return object.children()[index]
  }

  function selected_category() {
    return selected($('#CaseForm_case_case_category_id'))
  }

  function selected_cluster() {
    return selected($('#CaseForm_case_cluster_id'))
  }

  function show_all_components() {
    options().each(function(_index, opt) { $(opt).show() })
  }

  function filter_on_miss_match(collection, expected_id, callback) {
    collection.filter(function(_index, item) {
      return expected_id != callback(item)
    }).each(function(_index, item) { $(item).hide() })
  }

  function hide_components_on_selected_case_category() {
    selected_component_type_id = data_attr_id(selected_category(), 'component-type')

    // Hides components that do not match the select component type
    if(selected_component_type_id) {
      filter_on_miss_match(options(), selected_component_type_id, function(component) {
        return data_attr_id(component, 'component-type')
      })
    }
  }

  function hide_components_on_selected_cluster() {
    selected_cluster_id = data_attr_id(selected_cluster(), 'cluster')
    filter_on_miss_match(options(), selected_cluster_id, function(component) {
      return data_attr_id(component, 'cluster')
    })
  }

  function event_handler() {
    show_all_components()
    hide_components_on_selected_case_category()
    hide_components_on_selected_cluster()
  }

  // Applies the event handler and runs it on load
  $('#CaseForm_new_case').change(function(){ event_handler() })
  event_handler()
})
