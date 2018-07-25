class CreditCharge < CreditEvent
  belongs_to :case
  delegate :site, to: :case
  attr_readonly :case, :effective_date

  validates :amount, numericality: {
    greater_than_or_equal_to: 0,
    only_integer: true,
  }

  before_save :set_effective_date

  private

  def set_effective_date
    return if effective_date

    self.effective_date = Time.zone.local_to_utc(
      self.case.resolution_date ||
      self.case.completed_at ||
      self.case.created_at
    )
  end
end
