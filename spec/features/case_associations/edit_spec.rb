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
          cluster: cluster,
          name: "Component #{group}#{idx}"
        )
      }
    end
  end

  %w(1 2).each do |idx|
    let!("service_#{idx}".to_sym) {
      create(:service, name: "Service #{idx}", cluster: cluster)
    }
  end

  let(:checkbox_id_for) { ->(model) { "##{model.model_name}-#{model.id}" } }
  let(:checkbox_for) { ->(model) { find(checkbox_id_for[model], visible: :all) } }

  let(:ul_for_group_a) { "#ComponentGroup-#{component_group_a.id}-children" }
  let(:ul_for_group_b) { "#ComponentGroup-#{component_group_b.id}-children" }

  let(:cluster_tree_summary) { find('#cluster-tree-summary') }

  before(:each) do
    visit edit_cluster_case_associations_path(kase.cluster, kase, as: admin)
    wait_for_cluster_tree
  end

  context 'for a case with no associations' do
    let(:kase) {
      create(
        :open_case,
        cluster: cluster
      )
    }

    it 'marks nothing as associated' do
      cluster_checkbox = checkbox_for[cluster]

      expect(cluster_checkbox).not_to be_checked

      expect(
        find_all('input[type=checkbox]').map(&:checked?).reduce(false, :|)
      ).to eq false
    end

  end

  context 'for a case associated with an entire cluster' do
    let(:kase) {
      create(
        :open_case,
        cluster: cluster,
        clusters: [cluster]
      )
    }

    it 'marks entire cluster as associated' do
      cluster_checkbox = checkbox_for[cluster]

      expect(cluster_checkbox).to be_checked

      expect(
        find_all('input[type=checkbox]').map(&:checked?).reduce(true, :&)
      ).to eq true
    end

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
      find("#{ul_for_group_a}.show")  # Wait for it to exist
      expect(find(ul_for_group_a)[:class]).to match('show')
      expect(find(ul_for_group_b, visible: false)[:class]).not_to match('show')
    end

    #unless ENV.fetch('TRAVIS', false)
      # For reasons far beyond my ability to fathom, these tests pass locally but
      # fail on Travis. All clicks seem to be caught by the "Admin interface"
      # link in the navbar rather than the selected elements, which means that
      # these tests end up moving to /admin and consequently failing since they
      # can no longer access elements on the previous page.
      #
      # I've no idea why this is happening, and I've not got the time nor
      # inclination to spend any longer trying things in the vague hope of
      # finding out what's gone wrong.

      it 'can expand a collapsed group' do
        expand_group_b = "#ComponentGroup-#{component_group_b.id}-expand"
        click_button expand_group_b

        expect(find(ul_for_group_b)[:class]).to match('collapsing')
        sleep 1
        expect(find(ul_for_group_b)[:class]).to match('show')
      end

      it 'can collapse an expanded group' do
        expand_group_a = "#ComponentGroup-#{component_group_a.id}-expand"
        click_button expand_group_a

        expect(find(ul_for_group_a)[:class]).to match('collapsing')
        sleep 1
        expect(find(ul_for_group_a, visible: false)[:class]).not_to match('show')
      end

      it 'sets association to group when all children selected' do
        checkbox_for[component_a1].click
        checkbox_for[component_a2].click
        # a3 is already associated

        expect(checkbox_for[component_group_a]).to be_checked

        expect(cluster_tree_summary.text).to eq 'Group A Component a1 Component a2 Component a3'

        expect(SlackNotifier).to receive(:case_association_notification).with(kase, admin, anything)

        click_button 'Save'

        kase.reload

        expect(kase.components).to be_empty
        expect(kase.component_groups).to eq [component_group_a]

        expect(find('.alert-success')).to have_text "Updated affected components for support case #{kase.display_id}"

      end
    end
  #end

  context 'for a case with multiple associations' do
    let(:kase) {
      create(
        :open_case,
        cluster: cluster,
        components: [component_a1, component_a3],
        services: [service_1]
      )
    }

    it 'ticks all the right boxes' do
      expect(checkbox_for[component_a1]).to be_checked
      expect(checkbox_for[component_a2]).not_to be_checked
      expect(checkbox_for[component_a3]).to be_checked
      expect(checkbox_for[service_1]).to be_checked
      expect(checkbox_for[service_2]).not_to be_checked
    end
  end

  #unless ENV.fetch('TRAVIS', false)
    context 'for a case whose issue requires a certain service type' do
      let :service_type do
        create(:service_type, name: 'File System')
      end
      let :issue do
        create(:issue, requires_service: true, service_type: service_type)
      end
      let :service do
        create(:service, cluster: cluster, service_type: service_type)
      end
      let(:kase) {
        create(
          :open_case,
          cluster: cluster,
          services: [service, service_1],
          issue: issue
        )
      }

      it 'does not allow removing the association' do
        initial_number_of_audits = kase.associated_audits.where(auditable_type: 'CaseAssociation').count

        expect(checkbox_for[service]).to be_checked
        checkbox_for[service].click
        click_button 'Save'

        kase.reload
        expect(kase.associations).to include(service, service_1)
        expect(find('.alert-danger')).to have_text \
          "for issue '#{issue.name}' must be associated with " \
                "#{service_type.name} service but not given one"

        expect(kase.associated_audits.where(auditable_type: 'CaseAssociation').length)
          .to eq initial_number_of_audits  # No new audits added
      end
   # end

    context 'for a case whose issue does not require an association' do
      let(:issue) {
        create(:issue, requires_service: false, service_type: nil, name: 'Other')
      }
      let!(:service) do
        create(:service, cluster: cluster)
      end
      let(:kase) {
        create(
          :open_case,
          cluster: cluster,
          services: [service],
          issue: issue
        )
      }

      it 'allows removal of all associations' do

        expect(checkbox_for[service]).to be_checked
        checkbox_for[service].click
        click_button 'Save'

        kase.reload
        expect(kase.associations).to be_empty

      end
    end
  end

end
