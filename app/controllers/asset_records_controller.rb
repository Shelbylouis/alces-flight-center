class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
  end

  def update
    redirect_to asset
  end

  private

  def update_param
    definition_ids = asset.asset_record.map { |r| r.definition.id.to_s }
    params.permit(*definition_ids)
  end

  def asset
    @cluster_part || @component_group
  end
end
