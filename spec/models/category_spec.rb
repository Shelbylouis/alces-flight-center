require 'rails_helper'

RSpec.describe Category, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :category,
        id: 1,
        name: 'Broken Cluster',
      )
    end

    let :service_type { create(:service_type) }

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Broken Cluster',
      )
    end
  end
end
