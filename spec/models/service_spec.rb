require 'rails_helper'

RSpec.describe Service, type: :model do
  include_examples 'inheritable_support_type'
  include_examples 'maintenance_windows'

  describe '#case_form_json' do
    subject do
      create(
        :service,
        id: 1,
        name: 'Some Service',
        support_type: :managed,
        service_type: service_type
      )
    end

    let :service_type do
      create(:service_type)
    end

    def case_form_json_issue_names
      subject.case_form_json[:issues].pluck(:name)
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Some Service',
        supportType: 'managed',
        serviceType: service_type.case_form_json, # XXX remove?
        issues: []
      )
    end

    it 'includes Issue requiring Service of this type' do
      issue = create(
        :issue_requiring_service,
        name: 'my issue',
        service_type: service_type,
      )

      expect(case_form_json_issue_names).to eq [issue.name]
    end

    it 'includes Issue requiring Service of any type' do
      issue = create(
        :issue_requiring_service,
        name: 'my issue',
      )

      expect(case_form_json_issue_names).to eq [issue.name]
    end

    it 'does not include Issue requiring Service of different type' do
      create(
        :issue_requiring_service,
        name: 'my issue',
        service_type: create(:service_type),
      )

      expect(case_form_json_issue_names).to eq []
    end

    it 'does not include Issue not requiring Service' do
      create(:issue, name: 'my issue')

      expect(case_form_json_issue_names).to eq []
    end
  end
end
