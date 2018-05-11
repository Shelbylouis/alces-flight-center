class ServiceDecorator < ClusterPartDecorator
  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_service_becomes_advice_issue,
      request_managed_issue: Issue.request_service_becomes_managed_issue
    )
  end

  def path
    h.service_path(self)
  end

  def tabs
    [tabs_builder.overview, tabs_builder.cases, tabs_builder.maintenance]
  end

  def case_form_json
    super.merge(categories_or_issues)
  end

  private

  def categories_or_issues
    if any_categorised_issues?
      {categories: categorised_applicable_issues}
    else
      {issues: json_for_issues(applicable_issues)}
    end
  end

  def any_categorised_issues?
    applicable_issues.any?(&:category)
  end

  def categorised_applicable_issues
    applicable_issues
      .group_by(&:category)
      .transform_keys do |category|
      category.nil? ? Category.new(name: 'Other', id: -1) : category
    end.map do |category, issues|
      category.decorate.case_form_json.merge(issues: json_for_issues(issues))
    end.reject(&:nil?)
  end

  def applicable_issues
    issues_requiring_any_service = Issue.where(
      requires_service: true,
      service_type: nil
    )
    (service_type.issues + issues_requiring_any_service).reject(&:special?)
  end

  def json_for_issues(issues)
    issues.map { |issue| issue.decorate.case_form_json }
  end
end
