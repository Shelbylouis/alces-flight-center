require 'rails_helper'

RSpec.describe ComponentExpansion, type: :model do
  context 'with an invalid DefaultExpansion' do
    subject do
      ComponentExpansion.create(
        component_make_id: create(:component_make).id,
      )
    end

    it 'can not be associated with a component_make' do
      expect(subject.errors.messages).to include(:component_make_id)
    end

    it 'requires a component' do
      expect(subject.errors.messages).to include(:component)
    end
  end
end
