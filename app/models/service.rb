class Service < ApplicationRecord
  include ClusterPart

  belongs_to :service_type
  belongs_to :cluster

  delegate :description, to: :service_type

  def case_form_json
    super.merge(
      serviceType: service_type.case_form_json,
      **categories_or_issues
    )
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
      category.nil? ? Category.new(name: 'Other') : category
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
