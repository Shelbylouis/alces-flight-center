class CaseCategory < ApplicationRecord
  include AdminConfig::CaseCategory

  has_many :issues

  validates :name, presence: true

  def case_form_json
    issues_json = issues.map(&:case_form_json).reject(&:nil?)
    return if issues_json.empty?

    {
      id: id,
      name: name,
      issues: issues_json,
    }
  end
end
