class AssetRecordField < ApplicationRecord
  belongs_to :asset_record_field_definition
  belongs_to :component, optional: true
  belongs_to :component_group, optional: true

  alias_attribute :definition, :asset_record_field_definition

  # Field value can be an empty string, but not null.
  validates :value, exclusion: { in: [nil] }

  validates_with Validator

  def name
    # Conditional access needed as RailsAdmin will call this method to
    # determine the name to display for an instance, but when creating a new
    # instance no definition will be associated yet.
    definition&.field_name
  end

  # An AssetRecordField should be associated with precisely one Component or
  # ComponentGroup (the asset).
  def asset
    component || component_group
  end

  def component_type
    asset.component_type
  end
end
