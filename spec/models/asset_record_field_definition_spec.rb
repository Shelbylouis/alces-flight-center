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
end
