class Expansion < ApplicationRecord
  belongs_to :expansion_type

  before_validation :default_ports_to_zero

  validates :type, :slot, :ports, presence: true
  validates :ports, numericality: {
    greater_than_or_equal_to: 0,
    only_integer: true
  }

  private

  def default_ports_to_zero
    self.ports = 0 if ports.blank?
  end
end
