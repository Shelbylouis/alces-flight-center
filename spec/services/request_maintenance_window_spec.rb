require 'rails_helper'

# XXX Duplicates tests from `case#request_maintenance_window!` and Maintenance
# Window feature specs. Remove/change these?
RSpec.describe RequestMaintenanceWindow do
  include Rails.application.routes.url_helpers

  let :user { create(:user) }
  let :user_name { user.name }
  let :support_case { create(:case) }
  let :cluster { nil }
  let :component { nil }
  let :service { nil }

  subject do
    RequestMaintenanceWindow.new(
      case_id: support_case.id,
      user: user,
      cluster_id: cluster&.id,
      component_id: component&.id,
      service_id: service&.id
    ).run
  end

  describe 'main behaviour' do
    let :component { create(:component) }

    it 'creates new MaintenanceWindow and adds RT correspondence' do
      cluster = component.cluster

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: support_case.rt_ticket_id,
        text: /requested.*#{component.name}.*by #{user_name}.*must be confirmed.*#{cluster_url(cluster)}/
      )

      expect(subject.ended_at).to be nil
      expect(subject.user).to eq user
      expect(subject.case).to eq support_case
    end
  end

  context 'when given no associated model' do
    let :support_case { create(:case_with_component) }

    it "is associated with Case's associated model" do
      expect(subject.associated_model).to eq support_case.component
    end
  end

  context 'when given associated Component' do
    let :component { create(:component) }

    it 'is associated with Component' do
      expect(subject.associated_model).to eq component
    end
  end

  context 'when given associated Cluster' do
    let :cluster { create(:cluster) }

    it 'is associated with Cluster'  do
      expect(subject.associated_model).to eq cluster
    end
  end

  context 'when given associated Service' do
    let :service { create(:service) }

    it 'is associated with Service' do
      expect(subject.associated_model).to eq service
    end
  end
end
