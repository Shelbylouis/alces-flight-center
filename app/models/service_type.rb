
class ServiceType < ApplicationRecord
  has_many :services

  validates :name, presence: true

  scope :automatic, -> { where(automatic: true) }
end
