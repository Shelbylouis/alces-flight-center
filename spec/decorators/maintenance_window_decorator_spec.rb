require 'rails_helper'

RSpec.describe MaintenanceWindowDecorator do
  describe '#transition_info' do
    subject do
      create(:maintenance_window)
        .tap { |w| w.request!(requestor) }
        .decorate
    end

    let :requestor { create(:user, name: 'Some User') }

    it 'gives string with info on transition to this state' do
      info = subject.transition_info(:requested)

      user_name = requestor.name
      date_time = subject.requested_at.to_formatted_s(:short)
      expect(info).to eq(
        h.raw("By <em>#{user_name}</em> on <em>#{date_time}</em>")
      )
    end

    it 'gives false for transition which has not occurred' do
      info = subject.transition_info(:confirmed)

      expect(info).to be false
    end
  end
end
