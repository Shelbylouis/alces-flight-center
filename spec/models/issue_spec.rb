require 'rails_helper'

RSpec.describe Issue, type: :model do
  describe '#valid?' do
    context 'when associated with service_type and does not require_service' do
      subject do
        build(
          :issue,
          service_type: create(:service_type),
          requires_service: false
        )
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to match(
          service_type: ['can only require particular service type if issue requires service']
        )
      end
    end

    context 'when associated with service_type and does require_service' do
      subject do
        build(
          :issue,
          service_type: create(:service_type),
          requires_service: true
        )
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#case_form_json' do
    subject do
      create(
        :issue,
        id: 1,
        name: 'New user request',
        details_template: 'Give a username',
        requires_component: true,
        requires_service: false,
        support_type: :managed
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(id: 1,
                                           name: 'New user request',
                                           detailsTemplate: 'Give a username',
                                           requiresComponent: true,
                                           requiresService: false,
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
    let! :service_becomes_advice_issue do
      create(:issue, identifier: 'request_service_becomes_advice')
    end
    let! :service_becomes_managed_issue do
      create(:issue, identifier: 'request_service_becomes_managed')
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

    describe '#request_service_becomes_advice_issue' do
      it 'returns correct issue' do
        expect(
          Issue.request_service_becomes_advice_issue
        ).to eq service_becomes_advice_issue
      end
    end

    describe '#request_service_becomes_managed_issue' do
      it 'returns correct issue' do
        expect(
          Issue.request_service_becomes_managed_issue
        ).to eq service_becomes_managed_issue
      end
    end
  end
end
