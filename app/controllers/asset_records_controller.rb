class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
  end

  def update
    update_asset_record
    update_component_make
    if error_objects.empty?
      redirect_to asset
    else
      redirect_back fallback_location: @asset
    end
  end

  private

  def error_objects
    @error_objects ||= []
  end

  def update_asset_record
    asset.update_asset_record(asset_record_param.to_h)
         .reject(&:nil?)
         .reject(&:valid?)
         .tap { |errors| error_objects.concat errors }
  end

  def update_component_make
    return unless asset.is_a? ComponentGroup
    new_make = ComponentMake.find_by_id component_make_id_param
    asset.component_make = new_make
    asset.save!
  end

  def component_make_id_param
    params.require(:component_make).require(:id)
  end

  def asset_record_param
    definition_ids = asset.asset_record.map { |r| r.definition.id.to_s }
    params.permit(*definition_ids)
  end

  def asset
    @cluster_part || @component_group
  end
end
