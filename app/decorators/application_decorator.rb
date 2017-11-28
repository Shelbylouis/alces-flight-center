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

  def under_maintenance_icon
    h.icon(
      'wrench',
      inline: true,
      title: "#{readable_model_name.capitalize} currently under maintenance"
    ) if under_maintenance?
  end

  private

  def new_maintenance_window_path
    link_helper = "new_#{readable_model_name}_maintenance_window_path"
    h.send(link_helper, self)
  end

  def render_change_support_type_button(
    request_advice_issue:,
    request_managed_issue:,
    part_id_symbol:
  )
    # Do nothing if both `support_type` change Issues not passed.
    return unless request_advice_issue && request_managed_issue

    params = if managed?
               {
                 change_description: 'self-management',
                 button_class: 'btn-danger',
                 issue: request_advice_issue,
               }
             elsif advice?
               {
                 change_description: 'Alces management',
                 button_class: 'btn-success',
                 issue: request_managed_issue,
               }
             end.merge(part_id_symbol: part_id_symbol)
    change_support_type_button_with(**params)
  end

  def change_support_type_button_with(
    change_description:,
    button_class:,
    issue:,
    part_id_symbol:
  )
    h.button_to "Request #{change_description}",
      h.cases_path,
      class: "btn #{button_class} support-type-button",
      title: issue.name,
      params: {
        case: {
          cluster_id: cluster.id,
          part_id_symbol => id,
          issue_id: issue.id,
          details: 'User-requested from management dashboard'
        }
      },
      data: {
        confirm: "Are you sure you want to request #{change_description} of #{name}?"
      }
  end
end
