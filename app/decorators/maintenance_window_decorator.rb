class MaintenanceWindowDecorator < ApplicationDecorator
  delegate_all
  decorates_association :associated_model
  decorates_association :case

  def scheduled_period
    h.raw(
      [
        format(requested_start),
        '&mdash;',
        format(expected_end),
        scheduled_period_state_indicator,
      ].join(' ').strip
    )
  end

  def transition_info(state)
    user = public_send("#{state}_by")
    date = public_send("#{state}_at")
    transition_info_text(user, date)
  end

  def confirm_path
    h.confirm_cluster_maintenance_window_path(
       model.associated_cluster.id,
       model
    )
  end

  def case_attributes(form_action)
    {
      class: ['form-control is-valid'],
      'data-test': 'case-select',
    }.merge(
      conditional_attributes(action: form_action, field: 'Case')
    )
  end

  def duration_attributes(form_action)
    {
      min: 1,
      class: ["form-control #{bootstrap_valid_class(:duration)}"],
      required: true,
    }.merge(
      conditional_attributes(action: form_action, field: 'duration')
    )
  end

  def associated_model_names
    associated_models.map { |m| "#{m.name} (#{m.readable_model_name})"}.join(', ')
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

  def conditional_attributes(action:, field:)
    if action.confirm?
      {
        disabled: true,
        title: "The #{field} this maintenance has been requested for cannot be changed"
      }
    else
      {}
    end
  end
end
