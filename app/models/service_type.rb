
class ServiceType < ApplicationRecord
  include AdminConfig::ServiceType

  has_many :services

  validates :name, presence: true

  scope :automatic, -> { where(automatic: true) }

  def case_form_json
    {
      id: id,
      name: name,
    }
  end
end
