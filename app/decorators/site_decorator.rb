class SiteDecorator < ApplicationDecorator
  delegate_all
  decorates_association :clusters

  def case_form_buttons
    return unless managed_clusters.present?

    path = if h.current_user.admin?
             h.new_site_case_path(self)
           else
             h.new_case_path
           end

    case_form_button(path)
  end

  def tabs
    [tabs_builder.overview, tabs_builder.cases]
  end

  private

  # Handles the dynamic naming of paths when a contact is logged in
  def scope_name_for_paths
    h.current_user.contact? ? '_' : super
  end
end
