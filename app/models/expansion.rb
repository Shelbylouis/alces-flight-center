class Expansion < ApplicationRecord
  belongs_to :expansion_type
  validates :type, :slot, :ports, presence: true
  validates :ports, numericality: {
    greater_than_or_equal_to: 0,
    only_integer: true
  }
end
