class SiteDecorator < ApplicationDecorator
  delegate_all
  decorates_association :clusters

  def tabs
    [tabs_builder.overview, all_cases_tab]
  end

  def secondary_contacts_list
    users_list(
      users.secondary_contacts,
      title: 'Secondary site contact'
    )
  end

  def viewers_list
    users_list(
      users.viewers,
      title: 'Site viewer'
    )
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

  def users_list(users, title:)
    h.raw(
      [
        "<h4>#{title.pluralize(users.length)}</h4>",
        users_ul(users),
      ].join
    )
  end

  def users_ul(users)
    if users.present?
      items = users.map(&:decorate).map do |user|
        "<li>#{user.info}</li>"
      end.join
      "<ul>#{items}</ul>"
    else
      "<em>None</em>"
    end
  end
end
