require 'rails_helper'

RSpec.describe Category, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :category,
        id: 1,
        name: 'Broken Cluster',
      ).tap do |category|
        category.issues = [create(:issue, category: category)]
      end
    end

    let :service_type { create(:service_type) }

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Broken Cluster',
        issues: subject.issues.map(&:case_form_json),
      )
    end

    # XXX Currently every Category which contains special Issues only
    # contains these, so we can just remove these categories entirely; if this
    # ever changes then we'll probably need to change this to handle filtering
    # these out instead.
    it 'gives nothing when Category contains any special issues' do
      category = create(:category).tap do |category|
        category.issues = [create(:special_issue)]
      end

      expect(category.case_form_json).to be nil
    end
  end
end
