class Category < ApplicationRecord
  include AdminConfig::Category

  has_many :issues

  validates :name, presence: true

  def case_form_json
    return nil if issues.any?(&:special?)
    {
      id: id,
      name: name,
      issues: issues.map(&:case_form_json),
    }
  end
end
