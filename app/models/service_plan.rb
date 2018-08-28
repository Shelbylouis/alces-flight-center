class ServicePlan < ApplicationRecord
  belongs_to :cluster

  delegate :site, to: :cluster

  validates :start_date, presence: true
  validates :end_date, presence: true

  validate :end_after_start

  private

  def end_after_start
    return unless start_date.present? && end_date.present?
    errors.add(:end_date, 'must be on or after the start date') if end_date < start_date
  end
end
