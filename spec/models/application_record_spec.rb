require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '#readable_model_name' do
    # Create concrete model to test.
    subject { create(:component_group) }

    it 'returns lowercase, human-readable name of model' do
      expect(subject.readable_model_name).to eq 'component group'
    end
  end
end
