
RSpec.shared_examples 'maintenance_windows' do
  let :factory do
    SpecUtils.class_factory_identifier(described_class)
  end

  describe '#open_maintenance_windows' do
    subject { create(factory) }

    it 'returns non-ended associated maintenance windows' do
      create(:requested_maintenance_window, factory => subject, id: 1)
      create(:confirmed_maintenance_window, factory => subject, id: 2)
      create(:ended_maintenance_window, factory => subject, id: 3)

      resulting_window_ids = subject.open_maintenance_windows.map(&:id)

      expect(resulting_window_ids).to match_array([1, 2])
    end
  end
end
