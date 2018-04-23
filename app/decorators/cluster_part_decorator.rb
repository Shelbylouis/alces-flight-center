class ClusterPartDecorator < ApplicationDecorator
  delegate_all
  decorates_association :cluster

  def links
    self_link = h.link_to name, path
    h.raw("#{self_link} (#{cluster.links})")
  end

  private

  def render_change_support_type_button(
    request_advice_issue:,
    request_managed_issue:
  )
    return if internal

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
             end
    change_support_type_button_with(**params)
  end

  def change_support_type_button_with(
    change_description:,
    button_class:,
    issue:
  )
    tier = issue.tiers.find_by_level!(1)

    h.button_to "Request #{change_description}",
      h.cases_path,
      class: "btn #{button_class} support-type-button",
      title: issue.name,
      params: {
        case: {
          cluster_id: cluster.id,
          id_param_name => id,
          issue_id: issue.id,
          fields: tier.fields,
          tier_level: tier.level
        }
      },
      data: {
        confirm: "Are you sure you want to request #{change_description} of #{name}?"
      }
  end
end
