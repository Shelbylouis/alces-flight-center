class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
  end

  def update
    asset.update_asset_record(asset_record_param.to_h)
    update_component_make
    redirect_to asset
  end

  private

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
