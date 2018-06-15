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
    h.link_to(
      display_id,
      h.cluster_case_path(self.cluster, self),
      title: subject
    )
  end

  def request_maintenance_path
    assoc_class = model.associated_model.underscored_model_name
    h.send("new_#{assoc_class}_maintenance_window_path", model.associated_model, case_id: model.id)
  end

  def tier_description
    h.tier_description(tier_level)
  end

  def commenting_disabled_text
    commenting.disabled_text
  end

  private

  def commenting
    @commenting ||= CaseCommenting.new(self, current_user)
  end
end
