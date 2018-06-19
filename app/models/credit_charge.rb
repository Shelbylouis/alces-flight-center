class CreditCharge < CreditEvent
  belongs_to :case
  delegate :site, to: :case
  attr_readonly :case

  validates :amount, numericality: {
    greater_than_or_equal_to: 0,
    only_integer: true,
  }
end
