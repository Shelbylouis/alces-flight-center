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

    it 'renders Issues using their `case_form_json` method' do
      issue = create(:issue_requiring_service, name: 'my issue')

      expect(subject.case_form_json[:issues]).to eq([issue.case_form_json])
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

    it 'does not include special Issue which would otherwise be included' do
      create(:special_issue, requires_service: true, name: 'my issue')

      expect(case_form_json_issue_names).to eq []
    end

    it 'includes Issues nested within categories when an Issue has a Category' do
      category = create(:category)
      create(
        :issue_requiring_service,
        category: category,
        name: 'good category issue'
      )
      create(
        :issue_requiring_service,
        service_type: service_type,
        category: category,
        name: 'another good category issue'
      )
      create(:issue, category: category, name: 'bad category issue')

      categories = subject.case_form_json[:categories]

      expect(categories).to match [
        hash_including(category.case_form_json)
      ]

      category_issue_names = categories.first[:issues].pluck(:name)
      expect(category_issue_names).to match_array([
        'good category issue',
        'another good category issue',
      ])
    end

    it "includes 'Other' Category when only some Issues have categories" do
      category = create(:category, name: 'my category')
      create(
        :issue_requiring_service,
        category: category,
        name: 'category issue'
      )
      create(
        :issue_requiring_service,
        name: 'uncategorised issue'
      )

      categories = subject.case_form_json[:categories]

      expect(categories).to match_array([
        hash_including(
          name: 'my category',
          issues: [hash_including(name: 'category issue')],
        ),
        hash_including(
          name: 'Other',
          issues: [hash_including(name: 'uncategorised issue')],
          # 'Other' category, which does not exist in database, should just be
          # given an ID which will never otherwise be used so can decode and
          # uniquely identify it in the Case form app.
          id: -1
        ),
      ])
    end
  end
end
