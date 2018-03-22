module AssetRecordDecorator
  def edit_asset_record_path
    h.public_send "edit_#{asset_record_path_method_string}", object
  end

  def asset_record_path
    h.public_send asset_record_path_method_string, object
  end

  private

  def asset_record_path_method_string
    "#{underscored_model_name}_asset_record_path"
  end
end

