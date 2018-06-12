class CreditCharge < CreditEvent
  belongs_to :case
  delegate :site, to: :case
  attr_readonly :case

  validates :amount, numericality: {
    minimum: 0,
    only_integer: true,
  }
end
