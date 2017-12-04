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
        requires_component: false,
        requires_service: service_type.present?,
        service_type: service_type,
        support_type: :managed,
        chargeable: true
      )
    end

    let :service_type { create(:service_type) }

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'New user request',
        detailsTemplate: 'Give a username',
        requiresComponent: false,
        requiresService: true,
        serviceType: {
          id: service_type.id,
          name: service_type.name,
        },
        supportType: 'managed',
        chargeable: true
      )
    end

    context 'when no associated service_type' do
      let :service_type { nil }

      it 'has null serviceType' do
        expect(subject.case_form_json[:serviceType]).to be nil
      end
    end
  end

  describe 'special issues' do
    # Toggle issues.
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

    # Consultancy issues.
    let! :cluster_consultancy_issue do
      create(:issue, identifier: 'cluster_consultancy')
    end
    let! :component_consultancy_issue do
      create(:issue, identifier: 'component_consultancy')
    end
    let! :service_consultancy_issue do
      create(:issue, identifier: 'service_consultancy')
    end

    # There's a whole lot of pretty much identical tests here, may be worth
    # changing things to tidy this up.
    describe 'finder methods' do
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

      describe '#cluster_consultancy_issue' do
        it 'returns correct issue' do
          expect(
            Issue.cluster_consultancy_issue
          ).to eq cluster_consultancy_issue
        end
      end

      describe '#component_consultancy_issue' do
        it 'returns correct issue' do
          expect(
            Issue.component_consultancy_issue
          ).to eq component_consultancy_issue
        end
      end

      describe '#service_consultancy_issue' do
        it 'returns correct issue' do
          expect(
            Issue.service_consultancy_issue
          ).to eq service_consultancy_issue
        end
      end
    end

    describe '#special?' do
      it 'returns true for all special issues' do
        special_issues = [
          component_becomes_advice_issue,
          component_becomes_managed_issue,
          service_becomes_advice_issue,
          service_becomes_managed_issue,
          cluster_consultancy_issue,
          component_consultancy_issue,
          service_consultancy_issue,
        ]

        expect(special_issues.map(&:special?)).to eq([true] * special_issues.length)
      end

      it 'returns false for any other issue' do
        issue = create(:issue)

        expect(issue).not_to be_special
      end
    end
  end
end
