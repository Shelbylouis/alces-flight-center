class Site < ApplicationRecord
  has_many :contacts, dependent: :destroy
  validates :name, presence: true
end
