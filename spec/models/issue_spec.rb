require 'rails_helper'

RSpec.describe Issue, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :issue,
        id: 1,
        name: 'New user request',
        details_template: 'Give a username',
        requires_component: true,
        support_type: :managed
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'New user request',
        detailsTemplate: 'Give a username',
        requiresComponent: true,
        supportType: 'managed',
      })
    end
  end
end
