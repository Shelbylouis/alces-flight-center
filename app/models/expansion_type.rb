class ExpansionType < ApplicationRecord
  include AdminConfig::ExpansionType

  has_many :expansions

  def self.globally_available?
    true
  end
end
