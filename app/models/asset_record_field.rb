class AssetRecordField < ApplicationRecord
  belongs_to :asset_record_field_definition
  belongs_to :component, optional: true
  belongs_to :component_group, optional: true

  class << self
    private

    def unique_for_asset_validation_message
      proc do |field|
        <<-EOF.squish
        a field for this definition already exists for this
        #{field.asset.readable_model_name}, you should edit the existing field
        EOF
      end
    end
  end

  alias_attribute :definition, :asset_record_field_definition

  # Field value can be an empty string, but not null.
  validates :value, exclusion: { in: [nil] }

  validates :asset_record_field_definition,
            uniqueness: {
              scope: :component,
              if: :component,
              message: unique_for_asset_validation_message,
            }
  validates :asset_record_field_definition,
            uniqueness: {
              scope: :component_group,
              if: :component_group,
              message: unique_for_asset_validation_message,
            }

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
