class Check < ApplicationRecord
  belongs_to :check_category

  validates :name, presence: true
  validates :check_category, presence: true

  def self.globally_available?
    true
  end
end
