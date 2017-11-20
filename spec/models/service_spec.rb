require 'rails_helper'

RSpec.describe Service, type: :model do
  include_examples 'inheritable_support_type'

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

    let :service_type { create(:service_type) }

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Some Service',
        supportType: 'managed',
        serviceType: service_type.case_form_json
      )
    end
  end
end
