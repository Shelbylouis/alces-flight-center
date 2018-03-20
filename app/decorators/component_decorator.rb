class ComponentDecorator < ClusterPartDecorator
  include AssetRecordDecorator

  alias :case_form_buttons :cluster_part_case_form_buttons

  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_component_becomes_advice_issue,
      request_managed_issue: Issue.request_component_becomes_managed_issue,
      part_id_symbol: :component_id
    )
  end

  def path
    h.component_path(self)
  end

  def tabs
    [
      tabs_builder.overview,
      tabs_builder.asset_record,
      tabs_builder.cases,
      { id: :expansions, path: h.component_component_expansions_path(self) },
    ]
  end
end
