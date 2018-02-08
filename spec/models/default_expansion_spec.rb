require 'rails_helper'

RSpec.describe DefaultExpansion, type: :model do
  context 'with an invalid DefaultExpansion' do
    subject do
      DefaultExpansion.create(
        component_id: create(:component).id,
      )
    end

    it 'can not be associated with a component' do
      expect(subject.errors.messages).to include(:component_id)
    end

    it 'requires a component_make' do
      expect(subject.errors.messages).to include(:component_make)
    end
  end
end
