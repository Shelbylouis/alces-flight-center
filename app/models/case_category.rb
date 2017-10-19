class CaseCategory < ApplicationRecord
  include AdminConfig::CaseCategory

  has_many :issues

  validates :name, presence: true

  def case_form_json
    {
      id: id,
      name: name,
      issues: issues.map(&:case_form_json),
    }
  end
end
