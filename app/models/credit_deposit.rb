class CreditDeposit < CreditEvent
  belongs_to :cluster
  delegate :site, to: :cluster
  attr_readonly :cluster

  validates :amount, numericality: {
    greater_than_or_equal_to: 1,
    only_integer: true,
  }

  # When we add `effective_date`s to deposits, this and the equivalent method in
  # CreditCharge can be pulled up into CreditEvent
  scope :in_period, lambda { |start_date, end_date|
    where(created_at: start_date..end_date)
  }
end
