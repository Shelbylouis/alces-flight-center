require 'rails_helper'

RSpec.describe 'alces:maintenance_windows:progress' do
  include_context 'rake'

  let :unfinished_states do
    [
      :confirmed,
      :new,
      :requested,
      :started,
      :expired,
    ]
  end

  before :each do
    MaintenanceWindow.possible_states.each do |state|
      create(:maintenance_window, state: state)
    end
  end

  it_behaves_like 'it has prerequisite', :environment

  it 'attempts to progress all unfinished maintenance windows' do
    progressed_windows = []
    expect(
      ProgressMaintenanceWindow
    ).to receive(:new).exactly(5).times.and_wrap_original do |method, *args|
      method.call(*args).tap do |progress_mw|
        allow(progress_mw).to receive(:progress) do
          progressed_windows << progress_mw.window
        end
      end
    end

    subject.invoke

    progressed_window_states = progressed_windows.map(&:state).map(&:to_sym)
    expect(progressed_window_states).to match_array(unfinished_states)
  end

  describe 'logging' do
    let :logger { Rails.logger }

    before :each do
      expect(ActiveSupport::Logger).to receive(:new).with(
        'log/tasks/maintenance_windows/progress.log',
        'weekly',
      ).and_return(logger)
      allow(logger).to receive(:info)
    end

    it 'logs when task started' do
      expect(logger).to receive(:info).with(
        "#{task_name} running at #{DateTime.current.iso8601}"
      )

      subject.invoke
    end

    it 'logs result of each maintenance window progression' do
      unfinished_states.each do |state|
        expect(logger).to receive(:info).with(/Maintenance window.*#{state}/)
      end

      subject.invoke
    end
  end
end
