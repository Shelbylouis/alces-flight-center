class Tier < ApplicationRecord
  belongs_to :issue

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

  validates :fields,
    presence: {unless: :tool},
    absence: {if: :tool}

  validates :tool,
    absence: {
      unless: :can_have_tool?,
      message: 'must be a level 1 Tier without fields to associate tool'
    },
    inclusion: {in: ['motd'], if: :tool}

  def self.globally_available?
    true
  end

  def case_form_json
    {
      id: id,
      level: level,
    }.merge(fields_or_tool_json)
  end

  private

  def can_have_tool?
    level == 1 && !self.fields
  end

  def fields_or_tool_json
    if fields
      {fields: fields}
    else
      {tool: tool}
    end
  end
end
