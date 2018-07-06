require 'rails_helper'

RSpec.describe 'Case association edit form', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site, name: 'Test Cluster') }

  let(:component_group_a) {
    create(:component_group, cluster: cluster, name: 'Group A')
  }
  let(:component_group_b) {
    create(:component_group, cluster: cluster, name: 'Group B')
  }

  %w(a b).each do |group|
    %w(1 2 3).each do |idx|
      let!("component_#{group}#{idx}".to_sym) {
        create(
          :component,
          component_group: send("component_group_#{group}"),
          cluster: cluster
        )
      }
    end
  end

  %w(1 2).each do |idx|
    let!("service_#{idx}".to_sym) {
      create(:service, name: "Service #{idx}", cluster: cluster)
    }
  end

  context 'for a case with one association' do
    let(:kase) {
      create(
        :open_case,
        components: [component_a3],
        cluster: cluster
      )
    }

    it 'displays a partially-expanded tree' do
      visit edit_cluster_case_associations_path(kase.cluster, kase, as: admin)
      wait_for_cluster_tree

      ul_for_group_a = "#ComponentGroup-#{component_group_a.id}-children"

      expect(find(ul_for_group_a)[:class]).to match('show')
    end
  end
end
