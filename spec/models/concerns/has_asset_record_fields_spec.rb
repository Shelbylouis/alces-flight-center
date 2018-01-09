require 'rails_helper'

RSpec.describe HasAssetRecordFields, type: :model do
  let :parent do
    make_obj('parent-asset': 2, 'idx3-parent': 3)
  end

  subject do
    make_obj(parent, 'my-asset': 1, 'idx3-child': 3)
  end

  def make_obj(parent = nil, **fields)
    assets = fields.each_with_object([]) do |(msg, id), memo|
      definition = { definition: double(id: id) }
      d = double(AssetRecordField, **definition, value: msg.to_s)
      memo.push(d)
    end
    OpenStruct.new(
      name: 'Component-ish',
      asset_record_fields: assets,
      parent_asset_record_fields: parent&.asset_record_fields
    ).tap { |x| x.extend(HasAssetRecordFields) }
  end

  def asset_values(obj = subject)
    obj.asset_record_fields.map(&:value)
  end

  it 'includes the asset_record_fields for the current layer' do
    expect(asset_values).to include('my-asset')
  end

  it 'includes its parent assets' do
    expect(asset_values).to include('parent-asset')
  end

  it 'child assets override their parents' do
    expect(asset_values).to include('idx3-child')
    expect(asset_values).not_to include('idx3-parent')
  end
end
