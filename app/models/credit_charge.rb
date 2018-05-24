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
end
