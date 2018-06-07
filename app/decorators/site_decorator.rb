class SiteDecorator < ApplicationDecorator
  delegate_all
  decorates_association :clusters

  def tabs
    [tabs_builder.overview, all_cases_tab]
  end

  def secondary_contacts_list
    h.raw(
      [secondary_contacts_title, secondary_contacts_ul].join
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

  def secondary_contacts_title
    "<h4>Secondary site #{'contact'.pluralize(secondary_contacts.length)}</h4>"
  end

  def secondary_contacts_ul
    if secondary_contacts.present?
      items = secondary_contacts.map(&:decorate).map do |contact|
        "<li>#{contact.info}</li>"
      end.join
      "<ul>#{items}</ul>"
    else
      "<em>None</em>"
    end
  end

  def secondary_contacts
    @secondary_contacts ||= users.secondary_contacts
  end
end
