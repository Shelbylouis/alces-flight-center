class CreditEvent < ApplicationRecord
  self.abstract_class = true

  belongs_to :user

  validates :amount,
            presence: true,
            numericality: {
                only_integer: true,
            }

  validates :effective_date, presence: true, if: :persisted?

  attr_readonly :user, :amount, :effective_date

  scope :in_period, lambda { |start_date, end_date|
    where(effective_date: start_date..end_date)
  }

end
