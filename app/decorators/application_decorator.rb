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

  def case_form_button(path, disabled: false)
    title = <<~EOF.squish if disabled
      This #{readable_model_name} is self-managed; if required you
      may only request consultancy support from Alces Software.
    EOF

    card_header_button_link 'Create new support case',
      path,
      disabled: disabled,
      title: title
  end

  def consultancy_form_button(path)
    card_header_button_link 'Request consultancy', path
  end

  def card_header_button_link(text, path, disabled: false, title: nil)
    link = h.link_to text,
      path,
      class: ['nav-link', 'btn', 'btn-dark', disabled ? 'disabled' : nil],
      role: 'button',
      title: title

    h.raw("<li class=\"nav-item\" title=\"#{title}\">#{link}</li>")
  end
end
