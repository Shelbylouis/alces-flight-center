class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
  end

  def update
    update_component_make if asset.is_a? ComponentGroup
    update_asset_record
    if error_objects.empty?
      flash[:success] = 'Successfully updated the asset record'
      redirect_to asset
    else
      flash_errors
      redirect_back fallback_location: @asset
    end
  end

  private

  def flash_errors
    header = 'The following records failed to update:'
    error_flash_models(error_objects, header) do |model|
      "#{model.definition.field_name}: #{model.errors.full_messages}"
    end
  end

  def error_objects
    @error_objects ||= []
  end

  def update_asset_record
    asset.update_asset_record(asset_record_field_params.to_h)
         .reject(&:nil?)
         .reject(&:valid?)
         .tap { |errors| error_objects.concat errors }
  end

  def update_component_make
    new_make = ComponentMake.find_by_id component_make_id_param
    asset.component_make = new_make
    asset.save!
  end

  def component_make_id_param
    params.require(:component_make).require(:id)
  end

  def asset_record_field_params
    definition_ids = asset.asset_record.map { |r| r.definition.id.to_s }
    params.permit(*definition_ids)
  end

  def asset
    @cluster_part || @component_group
  end
end
