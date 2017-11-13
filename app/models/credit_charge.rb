class CreditCharge < ApplicationRecord
  belongs_to :case
  belongs_to :user

  validates :amount, presence: true
end
