require 'rails_helper'

RSpec.describe CaseCategory, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :case_category,
        id: 1,
        name: 'Broken Cluster',
        requires_component: true
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'Broken Cluster',
        requiresComponent: true
      })
    end
  end
end
