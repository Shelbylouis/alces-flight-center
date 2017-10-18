
RSpec.shared_examples 'editable asset record fields' do
  describe '#method_missing' do
    let :subject { create(:component) }

    let :definition_with_field do
      create(
        :asset_record_field_definition,
        component_types: [subject.component_type]
      )
    end

    before :each do
      subject.asset_record_fields.create!(
        definition: definition_with_field,
        value: 'field value'
      )
    end

    let :definition_without_field do
      create(
        :asset_record_field_definition,
        component_types: [subject.component_type]
      )
    end

    context "when sent #{described_class::ASSET_RECORD_FIELD_READER_REGEX}" do
      it 'returns field value when has associated field' do
        expect(
          subject.send(definition_with_field.identifier)
        ).to eq 'field value'
      end

      it 'returns nil when does not have associated field' do
        expect(
          subject.send(definition_without_field.identifier)
        ).to be nil
      end
    end

    describe "when sent #{described_class::ASSET_RECORD_FIELD_WRITER_REGEX}" do
      let :method { "#{definition.identifier}="}

      def field_for_definition(definition)
        subject
          .asset_record_fields
          .find_by_asset_record_field_definition_id(
            definition.id
          )
      end

      context 'when already has associated field for definition' do
        let :definition { definition_with_field }

        it 'updates associated field' do
          subject.send(method, 'new value')
          expect(
            field_for_definition(definition_with_field).value
          ).to eq 'new value'
        end

        it 'deletes associated field if sent empty value' do
          subject.send(method, '   ')
          expect(
            field_for_definition(definition_with_field)
          ).to be nil
        end
      end

      context 'when does not already have associated field for definition' do
        let :definition { definition_without_field }

        it 'creates new associated field' do
          subject.send(method, 'new value')
          expect(
            field_for_definition(definition_without_field).value
          ).to eq 'new value'
        end

        it 'does not create associated field if sent empty value' do
          subject.send(method, '   ')
          expect(
            field_for_definition(definition_without_field)
          ).to be nil
        end
      end
    end

    it 'behaves normally when sent other methods' do
      expect{
        subject.send(:some_other_method)
      }.to raise_error(NoMethodError)
    end
  end

  describe '#respond_to?' do
    # Ensure returns appropriately for methods handled by `method_missing`.
    it { is_expected.to respond_to('asset_record_field_definition_123') }
    it { is_expected.to respond_to('asset_record_field_definition_456=') }
    it { is_expected.not_to respond_to('arbitrary_other_things') }
  end
end
