class CreditEvent < ApplicationRecord
  self.abstract_class = true

  belongs_to :user

  validates :amount,
            presence: true,
            numericality: {
                only_integer: true,
            }

  attr_readonly :user, :amount

end
