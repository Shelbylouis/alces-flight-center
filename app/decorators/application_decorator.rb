class ApplicationDecorator < Draper::Decorator
  # Define methods for all decorated objects.
  # Helpers are accessed through `helpers` (aka `h`). For example:
  #
  #   def percent_amount
  #     h.number_to_percentage object.amount, precision: 2
  #   end

  def start_maintenance_request_link
    return unless h.current_user.admin?

    title = "Start request for maintenance of this #{readable_model_name}"
    h.link_to(
      h.raw(h.icon 'wrench', interactive: true),
      new_maintenance_window_path,
      title: title
    )
  end

  # Strictly speaking this gives the icons for a ClusterPart or entire Cluster,
  # but I don't have a better name for that yet.
  def cluster_part_icons
    icons = [internal_icon, *maintenance_icons]
    h.raw(icons.join)
  end

  private

  def internal_icon
    internal_text = "#{readable_model_name.capitalize} for internal Alces usage"
    if respond_to?(:internal) && internal
      h.image_tag(
        'flight-icon',
        alt: internal_text,
        title: internal_text,
      )
    end
  end

  def maintenance_icons
    maintenance_windows.map { |window| maintenance_icon(window) }
  end

  def maintenance_icon(window)
    return if window.ended?

    if window.awaiting_confirmation?
      classNames = 'faded-icon'
      title_base = "Maintenance has been requested for #{name}"
    elsif window.under_maintenance?
      classNames = nil
      title_base = "#{name} currently under maintenance"
    end

    title = "#{title_base} for ticket #{window.case.rt_ticket_id}"

    h.icon('wrench', inline: true, class: classNames, title: title)
  end

  def new_maintenance_window_path
    link_helper = "new_#{readable_model_name}_maintenance_window_path"
    h.send(link_helper, self)
  end

  # XXX de-dupe these?
  def case_form_button(path)
    link = h.link_to 'Create new support case',
      path,
      class: ['nav-link', 'btn', 'btn-dark'],
      role: 'button'

    h.raw("<li class=\"nav-item\">#{link}</li>")
  end

  def consultancy_form_button(path)
    link = h.link_to 'Request consultancy',
      path,
      class: ['nav-link', 'btn', 'btn-dark'],
      role: 'button'

    h.raw("<li class=\"nav-item\">#{link}</li>")
  end
end
