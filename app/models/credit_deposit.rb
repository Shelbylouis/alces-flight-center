class CreditDeposit < CreditEvent
  belongs_to :cluster
  delegate :site, to: :cluster
  attr_readonly :cluster

  validates :amount, numericality: {
    greater_than_or_equal_to: 1,
    only_integer: true,
  }

  validates :effective_date, presence: true

end
