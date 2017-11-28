require 'rails_helper'

# XXX Duplicates tests from `case#request_maintenance_window!` and Maintenance
# Window feature specs. Remove/change these?
RSpec.describe RequestMaintenanceWindow do
  include Rails.application.routes.url_helpers

  context 'when given Case and User' do
    let :support_case { create(:case_with_component) }
    let :user { create(:user) }
    let :user_name { user.name }
    let :component { support_case.component }
    let :component_name { component.name }
    let :cluster { support_case.cluster }

    it 'creates new MaintenanceWindow' do
      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: support_case.rt_ticket_id,
        text: /requested.*#{component_name}.*by #{user_name}.*must be confirmed.*#{cluster_url(cluster)}/
      )

      maintenance_window = RequestMaintenanceWindow.new(
        support_case: support_case,
        user: user
      ).run

      expect(maintenance_window.ended_at).to be nil
      expect(maintenance_window.user).to eq user
      expect(maintenance_window.case).to eq support_case
    end
  end
end
