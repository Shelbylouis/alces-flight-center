
RSpec.shared_examples 'canonical_name' do
  let(:factory) { SpecUtils.class_factory_identifier(described_class) }

  it 'has `canonical_name` generated on create' do
    object = build(factory, name: 'Original Name')
    expect(object.canonical_name).to be nil

    object.save!
    expect(object.canonical_name).to eq 'original-name'

    object.name = 'Some New Name'
    object.save!
    expect(object.canonical_name).to eq 'original-name'
  end

  it 'just gives validation error when name is `nil`' do
    expect do
      # Should just raise expected validation error for name being nil, rather
      # than getting NoMethodError due to attempting to call method on the nil
      # name (which used to happen).
      create(factory, name: nil)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end
