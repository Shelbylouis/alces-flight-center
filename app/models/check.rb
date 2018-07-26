class Check < ApplicationRecord
  belongs_to :check_category

  def self.globally_available?
    true
  end
end
