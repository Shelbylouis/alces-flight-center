require 'rails_helper'

RSpec.describe HasAssetRecordFields, type: :model do
  subject do
    assets = [
      double(AssetRecordField, value: 'my-asset')
    ] 
    OpenStruct.new(
      name: 'Component-ish',
      asset_record_fields: assets
    ).tap { |x| x.extend(HasAssetRecordFields) }
  end
 
  def asset_values(obj = subject)
    obj.asset_record_fields.map(&:value)
  end

  it 'includes the asset_record_fields for the current layer' do
    expect(asset_values).to include('my-asset')
  end
end
