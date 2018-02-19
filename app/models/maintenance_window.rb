class MaintenanceWindow < ApplicationRecord
  belongs_to :case
  belongs_to :requested_by,
    class_name: 'User'
  belongs_to :confirmed_by,
    class_name: 'User',
    required: false
  belongs_to :rejected_by,
    class_name: 'User',
    required: false
  belongs_to :cancelled_by,
    class_name: 'User',
    required: false

  belongs_to :cluster, required: false
  belongs_to :component, required: false
  belongs_to :service, required: false

  validate :validate_precisely_one_associated_model
  validates_presence_of :requested_start
  validates_presence_of :requested_end

  state_machine initial: :new do
    state :new, :requested do
      validates_absence_of :confirmed_at
      validates_absence_of :confirmed_by

      validates_absence_of :ended_at

      validates_absence_of :rejected_at
      validates_absence_of :rejected_by

      validates_absence_of :cancelled_at
      validates_absence_of :cancelled_by

      validates_absence_of :expired_at
    end

    state :confirmed do
      validates_presence_of :confirmed_at
      validates_presence_of :confirmed_by

      validates_absence_of :ended_at

      validates_absence_of :rejected_at
      validates_absence_of :rejected_by

      validates_absence_of :cancelled_at
      validates_absence_of :cancelled_by

      validates_absence_of :expired_at
    end

    state :ended do
      validates_presence_of :confirmed_at
      validates_presence_of :confirmed_by

      validates_presence_of :ended_at

      validates_absence_of :rejected_at
      validates_absence_of :rejected_by

      validates_absence_of :cancelled_at
      validates_absence_of :cancelled_by

      validates_absence_of :expired_at
    end

    state :rejected do
      validates_absence_of :confirmed_at
      validates_absence_of :confirmed_by

      validates_absence_of :ended_at

      validates_presence_of :rejected_at
      validates_presence_of :rejected_by

      validates_absence_of :cancelled_at
      validates_absence_of :cancelled_by

      validates_absence_of :expired_at
    end

    state :cancelled do
      validates_absence_of :ended_at

      validates_absence_of :rejected_at
      validates_absence_of :rejected_by

      validates_presence_of :cancelled_at
      validates_presence_of :cancelled_by

      validates_absence_of :expired_at
    end

    state :expired do
      validates_absence_of :confirmed_at
      validates_absence_of :confirmed_by

      validates_absence_of :ended_at

      validates_absence_of :rejected_at
      validates_absence_of :rejected_by

      validates_absence_of :cancelled_at
      validates_absence_of :cancelled_by

      validates_presence_of :expired_at
    end

    event :request do
      transition new: :requested
    end
    after_transition new: :requested do |model|
      model.add_maintenance_requested_comment
    end

    event :confirm do
      transition requested: :confirmed
    end
    before_transition requested: :confirmed do |model, transition|
      model.confirmed_at = DateTime.current
      model.confirmed_by = transition.args.first
    end
    after_transition requested: :confirmed do |model|
      model.add_maintenance_confirmed_comment
    end

    event :end do
      transition confirmed: :ended
    end
    before_transition confirmed: :ended do |model|
      model.ended_at = DateTime.current
    end
    after_transition confirmed: :ended do |model|
      model.add_maintenance_ended_comment
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

  def associated_cluster
    cluster || associated_model.cluster
  end

  def add_maintenance_requested_comment
    comment = <<-EOF.squish
      Maintenance requested for #{associated_model.name} by #{requested_by.name}; to
      proceed this maintenance must be confirmed on the cluster dashboard:
      #{cluster_dashboard_url}.
    EOF
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_confirmed_comment
    comment = <<~EOF.squish
      Maintenance of #{associated_model.name} confirmed by
      #{confirmed_by.name}; this #{associated_model.readable_model_name}
      is now under maintenance.
    EOF
    add_rt_ticket_correspondence(comment)
  end

  def add_maintenance_ended_comment
    comment = "#{associated_model.name} is no longer under maintenance."
    add_rt_ticket_correspondence(comment)
  end

  private

  delegate :add_rt_ticket_correspondence, :site, to: :case

  def validate_precisely_one_associated_model
    errors.add(
      :base, 'precisely one Cluster, Component, or Service can be under maintenance'
    ) unless number_associated_models == 1
  end

  def number_associated_models
    [cluster, component, service].select(&:present?).length
  end

  def cluster_dashboard_url
    Rails.application.routes.url_helpers.cluster_url(associated_cluster)
  end
end
