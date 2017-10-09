require 'rails_helper'

RSpec.describe Issue, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :issue,
        id: 1,
        name: 'New user request',
        requires_component: true
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'New user request',
        requiresComponent: true
      })
    end
  end
end
