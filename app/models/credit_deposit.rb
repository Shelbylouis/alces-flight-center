class CreditDeposit < ApplicationRecord
  belongs_to :cluster
  belongs_to :user

  # We only deal in whole credits so this must be an integer
  # I'm not going to restrict it to be positive since we might occasionally want
  # to do corrections or something...
  validates :amount,
            presence: true,
            numericality: {
              only_integer: true,
            }

  delegate :site, to: :cluster

  attr_readonly :cluster, :user, :amount

  scope :in_period, lambda { |start_date, end_date|
    where(created_at: start_date..end_date)
  }
end
