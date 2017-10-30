class Service < ApplicationRecord
  belongs_to :service_type
  belongs_to :cluster

  validates :name, presence: true
end
