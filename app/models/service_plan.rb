class ServicePlan < ApplicationRecord
  belongs_to :cluster

  validates :start_date, presence: true
  validates :end_date, presence: true
end
