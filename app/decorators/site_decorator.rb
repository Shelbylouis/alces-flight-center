class SiteDecorator < ApplicationDecorator
  delegate_all
  decorates_association :clusters

  def case_form_buttons
    return unless managed_clusters.present?
    case_form_button(new_scope_case_path)
  end

  def tabs
    [tabs_builder.overview, tabs_builder.cases]
  end

  private

  # Handles the dynamic naming of paths when a contact is logged in
  def scope_name_for_paths
    h.current_user.contact? ? '_' : super
  end

  # The site model is not required when a contact is logged in
  def arguments_for_scope_path(*a)
    h.current_user.contact? ? a : super
  end
end
