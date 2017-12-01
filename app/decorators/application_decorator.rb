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

  def maintenance_icons
    icons = maintenance_windows.map { |window| maintenance_icon(window) }
    h.raw(icons.join)
  end

  private

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
end
