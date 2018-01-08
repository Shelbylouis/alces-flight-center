class ExpansionType < ApplicationRecord
  has_many :expansions

  def self.globally_available?
    true
  end
end
