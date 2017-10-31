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
      expect(subject.case_form_json).to eq(id: 1,
                                           name: 'New user request',
                                           detailsTemplate: 'Give a username',
                                           requiresComponent: true,
                                           supportType: 'managed')
    end
  end

  describe 'special finder methods' do
    let! :component_becomes_advice_issue do
      create(:issue, identifier: 'request_component_becomes_advice')
    end
    let! :component_becomes_managed_issue do
      create(:issue, identifier: 'request_component_becomes_managed')
    end

    describe '#request_component_becomes_advice_issue' do
      it 'returns correct issue' do
        expect(
          Issue.request_component_becomes_advice_issue
        ).to eq component_becomes_advice_issue
      end
    end

    describe '#request_component_becomes_managed_issue' do
      it 'returns correct issue' do
        expect(
          Issue.request_component_becomes_managed_issue
        ).to eq component_becomes_managed_issue
      end
    end
  end
end
