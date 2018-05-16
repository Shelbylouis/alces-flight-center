class SiteDecorator < ApplicationDecorator
  delegate_all
  decorates_association :clusters

  def tabs
    [tabs_builder.overview, all_cases_tab]
  end

  private

  # Handles the dynamic naming of paths when a contact is logged in
  def scope_name_for_paths
    h.current_user.contact? ? '' : super
  end

  # The site model is not required when a contact is logged in
  def arguments_for_scope_path(*a)
    h.current_user.contact? ? a : super
  end

  def all_cases_tab
    tabs_builder.cases.tap do |tab|
      tab[:text] = 'All site cases'
    end
  end
end
