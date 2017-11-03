require 'rails_helper'

RSpec.describe CaseCategory, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :case_category,
        id: 1,
        name: 'Broken Cluster'
      ).tap do |case_category|
        case_category.issues = [create(:issue, case_category: case_category)]
      end
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(id: 1,
                                           name: 'Broken Cluster',
                                           issues: subject.issues.map(&:case_form_json))
    end
  end
end
