class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
    @subtitle = "#{@asset.name}"
  end

  def update
    redirect_to asset
  end

  private

  VALID_ASSET_IDS = [:component_id, :component_group_id]

  def asset
    id_key = id_param.keys.first
    id_key.to_s.chomp('_id').classify.constantize.find(id_param[id_key])
  end

  def id_param
    id = (params.keys & VALID_ASSET_IDS.map(&:to_s)).tap do |keys|
      raise 'Can not determine asset' unless keys.length == 1
    end
    params.permit(*id)
  end
end
