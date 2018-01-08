class Expansion < ApplicationRecord
  belongs_to :expansion_type
  validates :type, presence: true
end
