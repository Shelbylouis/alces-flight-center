class Expansion < ApplicationRecord
  belongs_to :expansion_type
  validates :type, :slot, :ports, presence: true
end
