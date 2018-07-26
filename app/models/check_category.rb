class CheckCategory < ApplicationRecord
  has_many :check

  def self.globally_available?
    true
  end
end
