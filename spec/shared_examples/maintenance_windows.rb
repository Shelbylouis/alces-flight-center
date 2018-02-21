
RSpec.shared_examples 'maintenance_windows' do
  let :factory do
    SpecUtils.class_factory_identifier(described_class)
  end

  describe '#open_maintenance_windows' do
    subject { create(factory) }

    it 'returns non-finished associated maintenance windows' do
      MaintenanceWindow.possible_states.map do |state|
        create(:maintenance_window, factory => subject, state: state)
      end

      open_windows = subject.open_maintenance_windows
      open_window_states = open_windows.map(&:state).map(&:to_sym)

      expect(open_window_states).to match_array([
        :confirmed,
        :new,
        :requested,
        :started,
      ])
    end
  end
end
