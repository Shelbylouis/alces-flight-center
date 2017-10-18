require 'rails_helper'

RSpec.describe Component, type: :model do
  describe '#case_form_json' do
    subject do
      create(
        :component,
        id: 1,
        name: 'Some Component',
        cluster: create(:cluster, id: 2)
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'Some Component'
      })
    end
  end
end
