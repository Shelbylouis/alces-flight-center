
class ServiceType < ApplicationRecord
  include AdminConfig::ServiceType

  has_many :services
  has_many :controlled_case_categories,
    class_name: 'CaseCategory',
    foreign_key: 'controlling_service_type_id'

  validates :name, presence: true

  scope :automatic, -> { where(automatic: true) }

  def case_form_json
    {
      id: id,
      name: name,
    }
  end
end
