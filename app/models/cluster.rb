class Cluster < ApplicationRecord
  SUPPORT_TYPES = ['managed', 'advice'].freeze
  belongs_to :site
  has_many :components, dependent: :destroy
  has_many :cases

  validates_associated :site
  validates :name, presence: true
  validates :support_type, inclusion: { in: SUPPORT_TYPES }
end
