require 'rails_helper'

RSpec.describe Service, type: :model do
  include_examples 'inheritable_support_type'

  describe '#case_form_json' do
    subject do
      create(
        :service,
        id: 1,
        name: 'Some Service',
        support_type: :managed
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(id: 1,
                                          name: 'Some Service',
                                          supportType: 'managed')
    end
  end
end
