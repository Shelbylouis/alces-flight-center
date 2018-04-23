class Tier < ApplicationRecord
  belongs_to :issue

  validates_presence_of :fields

  validates :level,
    presence: true,
    uniqueness: {
      scope: :issue,
      message: 'associated issue already has tier at this level'
    },
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 3,
    }

  def self.globally_available?
    true
  end

  def case_form_json
    {
      id: id,
      level: level,
      fields: fields,
    }
  end
end
