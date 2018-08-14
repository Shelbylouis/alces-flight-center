class CaseDecorator < ApplicationDecorator
  delegate_all
  decorates_association :change_request
  decorates_association :cluster
  decorates_association :issue

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

  def case_link
    h.link_to(
      display_id,
      h.case_path(self),
      title: subject
    )
  end

  def request_maintenance_path
    h.new_cluster_case_maintenance_path(model.cluster, model)
  end

  def tier_description
    h.tier_description(tier_level)
  end

  def commenting_disabled_text
    commenting.disabled_text
  end

  def available_issues
    services.map { |s| s.service_type.issues }
            .flatten
            .uniq
            .map(&:decorate)
            .sort_by { |i| i.category&.name || '' } +
      Issue.where(requires_component: false, requires_service: false)
        .decorate
        .reject(&:special?)
  end

  def formatted_time_since_last_update
    tslu = time_since_last_update.parts
    [].tap do |result|
      # Exclude seconds (we don't need to be that precise)
      ActiveSupport::Duration::PARTS[0..-2].each do |part|
        if tslu.include?(part)
          result << "#{tslu[part]}#{part.to_s[0]}"
        end
      end
    end.join(' ')
  end

  private

  def commenting
    @commenting ||= CaseCommenting.new(self, current_user)
  end

end
