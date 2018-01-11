require 'rails_helper'

RSpec.describe HasAssetRecords, type: :model do
  let :parent do
    create_asset(
      fields: { 'parent_asset_field': 2, 'parent_override_field': 3 }
    )
  end

  subject do
    create_asset(
      parent: parent,
      fields: { 'subject_asset_field': 1, 'subject_override_field': 3 }
    )
  end

  def create_asset(parent: nil, fields: {})
    assets = fields.each_with_object([]) do |(msg, id), memo|
      definition = { definition: double(id: id) }
      d = double(AssetRecordField, **definition, value: msg.to_s)
      memo.push(d)
    end
    OpenStruct.new(
      name: 'Component-ish',
      asset_record_fields: assets,
      asset_record_parent: parent
    ).tap { |x| x.extend(HasAssetRecords) }
  end

  def asset_values(obj = subject)
    obj.combined_asset_record_fields.map(&:value)
  end

  it 'includes the asset_record_fields for the current layer' do
    expect(asset_values).to include('subject_asset_field')
  end

  it 'includes its parent assets' do
    expect(asset_values).to include('parent_asset_field')
  end

  it 'subject assets override their parents' do
    expect(asset_values).to include('subject_override_field')
    expect(asset_values).not_to include('parent_override_field')
  end
end
