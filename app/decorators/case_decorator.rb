class CaseDecorator < ApplicationDecorator
  delegate_all
  decorates_association :change_request
  decorates_association :cluster

  def user_facing_state
    model.state.to_s.titlecase
  end

  def case_select_details
    [
      "#{display_id} #{subject}",
      created_at.to_formatted_s(:long),
      h.pluralize(model.associations.length, 'affected component'),
      "Created by #{user.name}"
    ].join(' | ')
  end

  def issue_type_text
    "#{category_text}#{model.issue.name}"
  end

  def case_link
    h.link_to(
      display_id,
      h.case_path(self),
      title: subject
    )
  end

  def request_maintenance_path
    h.new_cluster_maintenance_window_path model.cluster, case_id: model.id
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

  def category_text
    model.category ? "#{model.category.name}: " : ''
  end

end
