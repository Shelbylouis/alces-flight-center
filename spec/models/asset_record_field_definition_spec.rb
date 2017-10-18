require 'rails_helper'

RSpec.describe AssetRecordFieldDefinition, type: :model do
  describe '#settable_for_group?' do
    it 'is false when only settable at component-level' do
      definition = create(:asset_record_field_definition, level: 'component')
      expect(definition.settable_for_group?).to be false
    end

    it 'is true when settable at group-level' do
      definition = create(:asset_record_field_definition, level: 'group')
      expect(definition.settable_for_group?).to be true
    end
  end

  describe '#identifier' do
    subject { create(:asset_record_field_definition) }

    let :expected_identifier do
      "asset_record_field_definition_#{subject.id}".to_sym
    end

    it 'returns identifier suitable to use for accessor methods for fields for definition' do
      expect(subject.identifier).to eq expected_identifier
    end
  end
end
