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
    # Note: There are two "Other"s available: one that requires a service (any
    # service) and one which does not. To avoid having two indistinguishable
    # "Other"s in the list, we need to test for service association here
    # and include the correct "Other". This means not including issues that do
    # not require a service if we have at least one service (even though these
    # would be valid issues for this case).
    # At the moment only "Other" is affected by this but if we ever add Issues
    # that require no service but that should be available to all cases we'll
    # need to try harder.
    if services.empty?
      Issue.where(requires_component: false, requires_service: false)
           .decorate
           .reject(&:special?)
    else
      services.map { |s| s.service_type.issues }
        .flatten
        .uniq
        .map(&:decorate)
        .sort_by { |i| i.category&.name || '' } +
        Issue.where(requires_component: false, requires_service: true, service_type: nil)
          .decorate
          .reject(&:special?)
    end
  end

  def formatted_time_since_last_update
    return 'None' unless time_since_last_update
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
