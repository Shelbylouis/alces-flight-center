class Case < ApplicationRecord
  belongs_to :case_category
  belongs_to :cluster
  belongs_to :component, required: false
  belongs_to :user

  validates :details, presence: true
end
