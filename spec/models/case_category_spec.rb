require 'rails_helper'

RSpec.describe CaseCategory, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :case_category,
        id: 1,
        name: 'Broken Cluster'
      ).tap do |case_category|
        case_category.issues = [
          create(:issue, name: 'First', case_category: case_category)
        ]
      end
    end

    let :correct_json do
      {
        id: 1,
        name: 'Broken Cluster',
        issues: [
          subject.issues.first.case_form_json
        ]
      }
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(correct_json)
    end

    it 'does not include issues with `requires_service`' do
      create(:issue, case_category: subject, requires_service: true)
      subject.reload

      expect(subject.case_form_json).to eq(correct_json)
    end

    it 'gives nil when no issues' do
      expect(
        create(:case_category).case_form_json
      ).to be nil
    end
  end
end
