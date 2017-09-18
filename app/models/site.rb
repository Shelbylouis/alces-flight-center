class Site < ApplicationRecord
  has_many :contacts, dependent: :destroy
  has_many :clusters, dependent: :destroy
  has_many :components, dependent: :destroy
  validates :name, presence: true
end
