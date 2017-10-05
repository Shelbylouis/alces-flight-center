require 'rails_helper'

RSpec.describe Cluster, type: :model do
  describe '#case_form_json' do
    subject do
      create(:cluster, id: 1, name: 'Some Cluster', )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq({
        id: 1,
        name: 'Some Cluster'
      })
    end
  end
end
