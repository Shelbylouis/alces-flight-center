class Service < ApplicationRecord
  include AdminConfig::Service
  include ClusterPart

  belongs_to :service_type
  belongs_to :cluster

  delegate :description, to: :service_type

  def case_form_json
    super.merge(categories_or_issues)
  end

  def unfinished_related_maintenance_windows
    service = [self]
    service
      .map(&:maintenance_windows)
      .flat_map(&:unfinished)
      .sort_by(&:created_at)
      .reverse
  end

  private

  def categories_or_issues
    if any_categorised_issues?
      {categories: categorised_applicable_issues}
    else
      {issues: applicable_issues.map(&:case_form_json)}
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
      category.case_form_json.merge(issues: issues.map(&:case_form_json))
    end.reject(&:nil?)
  end

  def applicable_issues
    issues_requiring_any_service = Issue.where(
      requires_service: true,
      service_type: nil
    )
    (service_type.issues + issues_requiring_any_service).reject(&:special?)
  end
end
