class CreditDeposit < CreditEvent
  belongs_to :cluster
  delegate :site, to: :cluster
  attr_readonly :cluster
end
