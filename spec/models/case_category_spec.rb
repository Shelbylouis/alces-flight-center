require 'rails_helper'

RSpec.describe CaseCategory, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :case_category,
        id: 1,
        name: 'Broken Cluster',
        controlling_service_type: service_type
      ).tap do |case_category|
        case_category.issues = [create(:issue, case_category: case_category)]
      end
    end

    let :service_type { create(:service_type) }

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Broken Cluster',
        issues: subject.issues.map(&:case_form_json),
        controllingServiceType: {
          id: service_type.id,
          name: service_type.name,
        },
      )
    end

    context 'when no associated service_type' do
      let :service_type { nil }

      it 'has null controllingServiceType' do
        expect(subject.case_form_json[:controllingServiceType]).to be nil
      end
    end

    # XXX Currently every CaseCategory which contains special Issues only
    # contains these, so we can just remove these categories entirely; if this
    # ever changes then we'll probably need to change this to handle filtering
    # these out instead.
    it 'gives nothing when CaseCategory contains any special issues' do
      category = create(:case_category).tap do |category|
        category.issues = [create(:special_issue)]
      end

      expect(category.case_form_json).to be nil
    end
  end
end
