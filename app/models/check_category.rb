class CheckCategory < ApplicationRecord
  has_many :checks

  def self.globally_available?
    true
  end
end
