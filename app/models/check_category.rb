class CheckCategory < ApplicationRecord
  has_many :checks

  validates :name, presence: true

  def self.globally_available?
    true
  end
end
