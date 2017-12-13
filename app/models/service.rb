class Service < ApplicationRecord
  include ClusterPart

  belongs_to :service_type
  belongs_to :cluster

  delegate :description, to: :service_type

  def case_form_json
    super.merge(
      serviceType: service_type.case_form_json,
      issues: non_special_applicable_issues,
    )
  end

  private

  def non_special_applicable_issues
    applicable_issues.reject(&:special?)
  end

  def applicable_issues
    issues_requiring_any_service = Issue.where(
      requires_service: true,
      service_type: nil
    )
    service_type.issues + issues_requiring_any_service
  end
end
