class CreditCharge < ApplicationRecord
  belongs_to :case
  belongs_to :user

  validates :amount,
            presence: true,
            numericality: {
                only_integer: true,
            }

  delegate :site, to: :case

  attr_readonly :case, :user, :amount

  scope :in_period, lambda { |start_date, end_date|
    where(created_at: start_date..end_date)
  }
end
