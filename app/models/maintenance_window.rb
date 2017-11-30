class MaintenanceWindow < ApplicationRecord
  belongs_to :user
  belongs_to :case
  belongs_to :confirmed_by,
    class_name: 'User',
    required: false

  belongs_to :cluster, required: false
  belongs_to :component, required: false
  belongs_to :service, required: false

  validate :validate_precisely_one_associated_model

  delegate :add_rt_ticket_correspondence, to: :case

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

  def awaiting_confirmation?
    return false if ended_at
    !confirmed_by
  end

  def under_maintenance?
    return false if ended_at
    confirmed_by
  end

  def ended?
    !!ended_at
  end

  private

  def validate_precisely_one_associated_model
    errors.add(
      :base, 'precisely one Cluster, Component, or Service can be under maintenance'
    ) unless number_associated_models == 1
  end

  def number_associated_models
    [cluster, component, service].select(&:present?).length
  end
end
