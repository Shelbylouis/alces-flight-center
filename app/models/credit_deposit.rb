class CreditDeposit < ApplicationRecord
  belongs_to :cluster
  belongs_to :user

  validates :amount, presence: true
end
