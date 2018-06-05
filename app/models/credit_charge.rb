class CreditCharge < CreditEvent
  belongs_to :case
  delegate :site, to: :case
  attr_readonly :case
end
