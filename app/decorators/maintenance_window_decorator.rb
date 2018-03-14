class MaintenanceWindowDecorator < ApplicationDecorator
  delegate_all
  decorates_association :associated_model
  decorates_association :case

  def scheduled_period
    h.raw(
      [
        format(requested_start),
        '&mdash;',
        format(requested_end),
        scheduled_period_state_indicator,
      ].join(' ').strip
    )
  end

  def transition_info(state)
    user = public_send("#{state}_by")
    date = public_send("#{state}_at")
    transition_info_text(user, date)
  end

  private

  def scheduled_period_state_indicator
    case state.to_sym
    when :started
      '<strong>(in progress)</strong>'
    when :expired
      title = <<-TITLE.squish
        This maintenance was not confirmed before the requested start date; a
        new time slot must be chosen for this maintenance to occur.
      TITLE
      "<strong title=\"#{title}\">(expired)</strong>"
    else
      ''
    end
  end

  def transition_info_text(user, date)
    return false unless user && date
    h.raw("By <em>#{user.name}</em> on <em>#{format(date)}</em>")
  end

  def format(date_time)
    date_time.to_formatted_s(:short)
  end
end
