class AssetRecordFieldDefinition < ApplicationRecord
  SETTABLE_LEVELS = [
    # Settable at group-level; overridable at component-level.
    'group',

    # Settable at component-level only.
    'component',
  ].freeze

  has_and_belongs_to_many :component_types
  has_many :asset_record_fields

  validates :field_name, presence: true
  validates :level, inclusion: { in: SETTABLE_LEVELS }, presence: true

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting level.
  def level_enum
    SETTABLE_LEVELS
  end

  def settable_for_group?
    level == 'group'
  end
end
