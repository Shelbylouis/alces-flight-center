class MaintenanceWindowDecorator < ApplicationDecorator
  delegate_all
  decorates_association :associated_model

  def transition_info(state)
    user = public_send("#{state}_by")
    date = public_send("#{state}_at")
    transition_info_text(user, date)
  end

  private

  def transition_info_text(user, date)
    return false unless user && date
    formatted_date = date.to_formatted_s(:short)
    h.raw("By <em>#{user.name}</em> on <em>#{formatted_date}</em>")
  end
end
