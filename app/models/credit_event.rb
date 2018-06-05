class CreditEvent < ApplicationRecord
  self.abstract_class = true

  belongs_to :user

  validates :amount,
            presence: true,
            numericality: {
                only_integer: true,
            }

  attr_readonly :user, :amount

  scope :in_period, lambda { |start_date, end_date|
    where(created_at: start_date..end_date)
  }
end
