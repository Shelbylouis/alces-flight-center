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

  # XXX duplicated from Component specs.
  describe '#under_maintenance?' do
    subject do
      create(:service).tap do |service|
        create(:case_requiring_service, service: service).tap do |support_case|
          create(:closed_maintenance_window, case: support_case)
        end
      end
    end

    context 'when has case which is under maintenance' do
      before :each do
        subject.tap do |service|
          create(:case_requiring_service, service: service).tap do |support_case|
            create(:unconfirmed_maintenance_window, case: support_case)
          end
        end
      end

      it { is_expected.to be_under_maintenance }
    end

    context 'when has no case which is under maintenance' do
      it { is_expected.not_to be_under_maintenance }
    end
  end

end
