require 'rails_helper'

RSpec.describe MaintenanceWindowDecorator do
  describe '#transition_info' do
    subject do
      create(:maintenance_window)
        .tap { |w| w.request!(requestor) }
        .decorate
    end

    let :requestor { create(:admin, name: 'Some User') }

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

  describe '#scheduled_period' do
    it 'returns formatted time range for maintenance' do
      requested_start = DateTime.current.advance(days: 1)
      requested_end = DateTime.current.advance(days: 2)
      window = create(
        :maintenance_window,
        requested_start: requested_start,
        requested_end: requested_end,
      ).decorate

      from = requested_start.to_formatted_s(:short)
      to = requested_end.to_formatted_s(:short)
      expect(window.scheduled_period).to include h.raw("#{from} &mdash; #{to}")
    end

    it 'indicates if the maintenance is in progress' do
      window = create(:maintenance_window, state: :started).decorate

      expect(window.scheduled_period).to include '(in progress)'
    end
  end
end
