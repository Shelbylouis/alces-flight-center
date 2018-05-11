class Category < ApplicationRecord
  include AdminConfig::Category

  has_many :issues

  validates :name, presence: true

  def self.globally_available?
    true
  end
end
