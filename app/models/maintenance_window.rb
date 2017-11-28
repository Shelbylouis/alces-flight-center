class MaintenanceWindow < ApplicationRecord
  belongs_to :user
  belongs_to :case
  belongs_to :confirmed_by,
    class_name: 'User',
    required: false

  belongs_to :cluster, required: false
  belongs_to :component, required: false
  belongs_to :service, required: false

  def associated_model
    component || service || cluster
  end

  def associated_model=(model)
    case model
    when Cluster
      self.cluster = model
    when Component
      self.component = model
    when Service
      self.service = model
    end
  end
end
