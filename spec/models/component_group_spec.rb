require 'rails_helper'

RSpec.describe ComponentGroup, type: :model do
  it_behaves_like 'it belongs to Cluster'

  describe '#genders_host_range=' do
    it 'causes any needed associated Components to be created on save, based on the expanded host range' do
      # Create an existing saved component associated with the group, with a
      # name that matches the host range, to test that an extra component with
      # this name is not created; components should only be created for names
      # for which components do not already exist.
      existing_component = create(:component, name: 'node01')
      group = existing_component.component_group

      group.reload
      expect(group.component_names).to eq(['node01'])

      group.genders_host_range = 'node[01-03]'
      group.save!

      group.reload
      expect(group.component_names).to match_array(['node01', 'node02', 'node03'])
    end

    it 'does not cause any nodes to be created when unset' do
      group = create(:component_group)

      group.save!

      group.reload
      expect(group.component_names).to eq []
    end
  end
end
