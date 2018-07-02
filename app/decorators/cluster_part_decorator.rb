class ClusterPartDecorator < ApplicationDecorator
  delegate_all
  decorates_association :cluster

  def links
    self_link = h.link_to name, path
    h.raw("#{self_link} (#{cluster.links})")
  end

  def case_form_json
    {
      id: id,
      name: name,
      supportType: support_type,
    }
  end

  def fa_icon
    'fa-cube'
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
                 change_details: <<~EOF,
                   When a #{readable_model_name} is self-managed you will only
                   be able to request consultancy support in relation to it
                   from Alces Software, which is chargeable at the usual rates
                   for your cluster.
                 EOF
                 button_class: 'btn-danger',
                 issue: request_advice_issue,
               }
             elsif advice?
               {
                 change_description: 'Alces management',
                 change_details: <<~EOF,
                   When a #{readable_model_name} is managed by Alces Software
                   you relinquish direct control over it, and may request a
                   wider range of support in relation to it from Alces
                   Software.
                 EOF
                 button_class: 'btn-success',
                 issue: request_managed_issue,
               }
             end
    change_support_type_button_with(**params)
  end

  def change_support_type_button_with(
    change_description:,
    change_details:,
    button_class:,
    issue:
  )
    tier = issue.tiers.find_by_level!(1)

    confirm_question =
      "Are you sure you want to request #{change_description} of #{name}?"
    confirm_text = [confirm_question, change_details.squish].join("\n\n")

    default_html_options = {
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
      data: { confirm: confirm_text }
    }

    action_description = "request #{change_description} of a #{readable_model_name}"
    html_options = PolicyDependentOptions.wrap(
      default_html_options,
      policy: policy(Case).create?,
      action_description: action_description,
      user: h.current_user
    )

    h.button_to "Request #{change_description}", h.cases_path, html_options
  end
end
