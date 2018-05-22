class Service < ApplicationRecord
  include AdminConfig::Service
  include ClusterPart

  belongs_to :service_type
  belongs_to :cluster

  delegate :description, to: :service_type

  validates_associated :cluster
end
