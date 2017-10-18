
RSpec.shared_examples 'canonical_name' do
  it 'has `canonical_name` generated on create' do
    factory_identifier = described_class.to_s.downcase
    object = build(factory_identifier, name: 'Original Name')
    expect(object.canonical_name).to be nil

    object.save!
    expect(object.canonical_name).to eq 'original-name'

    object.name = 'Some New Name'
    object.save!
    expect(object.canonical_name).to eq 'original-name'
  end
end
