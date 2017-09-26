class CaseCategory < ApplicationRecord
  belongs_to :component_type, required: false

  validates :name, presence: true
end
