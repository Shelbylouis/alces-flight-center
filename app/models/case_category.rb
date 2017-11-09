class CaseCategory < ApplicationRecord
  include AdminConfig::CaseCategory

  has_many :issues
  belongs_to :controlling_service_type,
    class_name: 'ServiceType',
    required: false

  validates :name, presence: true

  def case_form_json
    {
      id: id,
      name: name,
      issues: issues.map(&:case_form_json),
    }
  end
end
