class CreditDeposit < CreditEvent
  belongs_to :cluster
  delegate :site, to: :cluster
  attr_readonly :cluster

  validates :amount, numericality: {
    minimum: 1,
    only_integer: true,
  }
end
