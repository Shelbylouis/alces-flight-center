class CaseDecorator < ApplicationDecorator
  delegate_all

  def user_facing_state
    model.state.to_s.titlecase
  end

  def case_select_details
    [
      "#{display_id} #{subject}",
      created_at.to_formatted_s(:long),
      associated_model.name,
      "Created by #{user.name}"
    ].join(' | ')
  end

  def association_info
    associated_model.decorate.links
  end

  def case_link
    h.link_to(display_id, h.case_path(self), title: subject)
  end

  def chargeable_symbol
    h.boolean_symbol(chargeable)
  end

  def request_maintenance_path
    assoc_class = model.associated_model.underscored_model_name
    h.send("new_#{assoc_class}_maintenance_window_path", model.associated_model, case_id: model.id)
  end

  def tier_description
    h.tier_description(tier_level)
  end

  def commenting_disabled?
    current_user.contact? && !consultancy?
  end
end
