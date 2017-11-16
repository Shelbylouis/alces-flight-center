class CreditCharge < ApplicationRecord
  belongs_to :case
  belongs_to :user

  delegate :site, to: :case

  validates :amount, presence: true
end
