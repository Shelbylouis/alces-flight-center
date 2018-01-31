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

  describe '#data_type' do
    around :each do |example|
      ActiveSupport::Deprecation.silence { example.run }
    end

    context 'with the data_type set to "long_text"' do
      subject do
        create(:asset_record_field_definition, data_type: 'long_text')
      end

      it 'returns the correct value' do
        expect(subject.data_type).to eq('long_text')
      end

      it 'does not issue a deprecation warning' do
        expect(ActiveSupport::Deprecation).not_to receive(:warn)
        subject.data_type
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  
    context 'with the data_type db entry set to nil' do
      subject do
        create(:asset_record_field_definition, data_type: nil)
      end
      
      it 'defaults to "short_text"' do
        expect(subject.data_type).to eq('short_text')
      end

      it 'issues a deprecation warning' do
        expect(ActiveSupport::Deprecation).to receive(:warn)
        subject.data_type
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  describe '#valid?' do
    context 'with a "forgein_data_type"' do
      let :type { 'forgein_data_type' }

      subject do
        create(:asset_record_field_definition, data_type: type)
      end

      it 'is invalid with a "forgein_data_type"' do
        expect(subject).not_to be_valid
      end
    end
  end
end

