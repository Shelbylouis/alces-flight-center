
class ServiceType < ApplicationRecord
  include AdminConfig::ServiceType

  has_many :services

  validates :name, presence: true

  scope :automatic, -> { where(automatic: true) }
end
