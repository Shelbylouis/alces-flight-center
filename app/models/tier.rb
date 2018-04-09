class Tier < ApplicationRecord
  belongs_to :issue

  def self.globally_available?
    true
  end
end
