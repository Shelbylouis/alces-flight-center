require 'rails_helper'

# XXX Duplicates tests from `case#request_maintenance_window!` and Maintenance
# Window feature specs. Remove/change these?
RSpec.describe RequestMaintenanceWindow do
  include Rails.application.routes.url_helpers

  let :user { create(:user) }
  let :user_name { user.name }
  let :support_case { create(:case) }
  let :associated_model { nil }

  subject do
    RequestMaintenanceWindow.new(
      support_case: support_case,
      user: user,
      associated_model: associated_model
    ).run
  end

  describe 'main behaviour' do
    let :associated_model { create(:component) }

    it 'creates new MaintenanceWindow and adds RT correspondence' do
      cluster = associated_model.cluster

      expect(Case.request_tracker).to receive(
        :add_ticket_correspondence
      ).with(
        id: support_case.rt_ticket_id,
        text: /requested.*#{associated_model.name}.*by #{user_name}.*must be confirmed.*#{cluster_url(cluster)}/
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
    let :associated_model { component }

    it 'is associated with Component' do
      expect(subject.associated_model).to eq component
    end
  end

  context 'when given associated Cluster' do
    let :cluster { create(:cluster) }
    let :associated_model { cluster }

    it 'is associated with Cluster'  do
      expect(subject.associated_model).to eq cluster
    end
  end

  context 'when given associated Service' do
    let :service { create(:service) }
    let :associated_model { service }

    it 'is associated with Service' do
      expect(subject.associated_model).to eq service
    end
  end
end
