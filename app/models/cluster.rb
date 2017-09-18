class Cluster < ApplicationRecord
  belongs_to :site
  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: %w(manged | advice) }
end
