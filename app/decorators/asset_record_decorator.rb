module AssetRecordDecorator
  def edit_asset_record_path
    File.join(asset_record_path, 'edit')
  end

  def asset_record_path
    File.join(model_id_path, 'asset_record')
  end

  private

  def model_id_path
    File.join('', object.class.to_s.tableize.gsub('_', '-'), object.id.to_s)
  end
end
