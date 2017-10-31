class ComponentDecorator < ApplicationDecorator
  delegate_all

  def change_support_type_button
    params = if managed?
               {
                 change_description: 'self-management',
                 button_class: 'btn-danger',
                 issue: Issue.request_component_becomes_advice_issue,
               }
             elsif advice?
               {
                 change_description: 'Alces management',
                 button_class: 'btn-success',
                 issue: Issue.request_component_becomes_managed_issue,
               }
             end
    change_support_type_button_with(**params)
  end

  private

  def change_support_type_button_with(change_description:, button_class:, issue:)
      h.button_to "Request #{change_description}",
        h.cases_path,
        class: "btn #{button_class} support-type-button",
        title: issue.name,
        params: {
          case: {
            cluster_id: cluster.id,
            component_id: id,
            issue_id: issue.id,
            details: 'User-requested from management dashboard'
          }
        },
        data: {
          confirm: "Are you sure you want to request #{change_description} of #{name}?"
        }
  end
end
