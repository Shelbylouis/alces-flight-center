class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
  end

  def update
    update_component_make if asset.is_a? ComponentGroup
    failed_updates = update_asset_record.reject(&:nil?)
                                        .reject(&:valid?)
    if failed_updates.empty?
      flash[:success] = 'Successfully updated the asset record'
      redirect_to asset
    else
      header = 'The following records failed to update:'
      error_flash_models(failed_updates, header) do |model|
        "#{model.definition.field_name}: #{model.errors.full_messages}"
      end
      redirect_back fallback_location: @asset
    end
  end

  private

  def update_asset_record
    asset.update_asset_record(asset_record_field_params.to_h)
  end

  def update_component_make
    new_make = ComponentMake.find_by_id component_make_id_param
    asset.update!(component_make: new_make)
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
