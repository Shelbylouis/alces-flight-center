class AssetRecordField < ApplicationRecord
  belongs_to :asset_record_field_definition
  belongs_to :component, optional: true
  belongs_to :component_group, optional: true

  # Field value can be an empty string, but not null.
  validates :value, exclusion: { in: [nil] }
end
