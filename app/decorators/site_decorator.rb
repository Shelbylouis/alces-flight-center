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

  def terminal_service_url(service)
    base_url = ENV.fetch('TERMINAL_SERVICE_BASE_URL')
    "#{base_url}#{terminal_service_path(service)}"
  end

  def terminal_service_path(service)
    if current_user.admin?
      "/sites/#{to_param}/#{service.service_type}"
    else
      "/#{service.service_type}"
    end
  end

  def terminal_services
    super.sort_by {|s| s.center_ui['title']}
  end

  private

  # When a Site user is signed in we don't want/need the `/sites/:site_id`
  # prefix to Site URLs, otherwise we do.
  def scope_name_for_paths
    h.current_user.site_user? ? '' : super
  end

  # Similarly to above, we don't want/need to pass the Site as the first
  # argument to the scope path helper (as `super` does) for Site users.
  def arguments_for_scope_path(*a)
    h.current_user.site_user? ? a : super
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
