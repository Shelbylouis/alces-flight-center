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

  delegate :add_rt_ticket_correspondence, :site, to: :case

  state_machine initial: :requested do
    state :requested do
      validates_absence_of :confirmed_by
      validates_absence_of :ended_at
    end

    state :confirmed do
      validates_presence_of :confirmed_by
      validates_absence_of :ended_at
    end

    state :ended do
      validates_presence_of :confirmed_by
      validates_presence_of :ended_at
    end

    event :confirm do
      transition requested: :confirmed
    end
    before_transition requested: :confirmed do |model, transition|
      model.confirmed_by = transition.args.first
    end

    event :end do
      transition confirmed: :ended
    end
    before_transition confirmed: :ended do |model, _transition|
      model.ended_at = DateTime.current
    end
  end

  alias_method :in_progress?, :confirmed?

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
