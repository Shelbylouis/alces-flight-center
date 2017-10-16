require 'rails_helper'

RSpec.describe AssetRecordField, type: :model do
  describe('#valid?') do
    subject do
      build(:unassociated_asset_record_field, definition: field_definition)
    end

    let :field_definition { create(:asset_record_field_definition) }

    let :component_group do
      create(:component_group).tap do |group|
        group.component_type.asset_record_field_definitions << field_definition
      end
    end

    let :component do
      create(:component, component_group: component_group)
    end

    context 'when associated with neither component nor group' do
      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to include(
          base: [/must be associated with either component or component group/]
        )
      end
    end

    context 'when associated with just component' do
      before :each do
        subject.component = component
      end

      it { is_expected.to be_valid }

      context 'when associated with field definition which is not associated with component type' do
        before :each do
          subject.definition = create(:asset_record_field_definition)
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            asset_record_field_definition: [/is not a field definition associated with component type/]
          )
        end
      end

      context 'when updating existing field' do
        before :each do
          subject.save!
          subject.reload
        end

        it { is_expected.to be_valid }
      end

      context 'when a field using same definition is already associated with component' do
        before :each do
          create(
            :unassociated_asset_record_field,
            definition: subject.definition,
            component: subject.component
          )
          component.reload
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            asset_record_field_definition: [/a field for this definition already exists for this component/]
          )
        end
      end
    end

    context 'when associated with just group' do
      before :each do
        subject.component_group = component_group
      end

      it { is_expected.to be_valid }

      context 'when associated with field definition which is not associated with component type' do
        before :each do
          subject.definition = create(:asset_record_field_definition)
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            asset_record_field_definition: [/is not a field definition associated with component type/]
          )
        end
      end

      context 'when field definition is settable at component-level only' do
        before :each do
          field_definition.level = :component
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            asset_record_field_definition: [/this field is only settable at the component-level/]
          )
        end
      end

      context 'when updating existing field' do
        before :each do
          subject.save!
          subject.reload
        end

        it { is_expected.to be_valid }
      end

      context 'when a field using same definition is already associated with component group' do
        before :each do
          create(
            :unassociated_asset_record_field,
            definition: subject.definition,
            component_group: subject.component_group
          )
          component_group.reload
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            asset_record_field_definition: [/a field for this definition already exists for this component group/]
          )
        end
      end
    end

    context 'when associated with both component and group' do
      before :each do
        subject.component = component
        subject.component_group = component_group
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to include(
          base: [/can only be associated with either component or component group/]
        )
      end
    end
  end
end
