require 'rails_helper'

RSpec.describe Cluster, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_description'

  describe '#valid?' do
    subject { create(:cluster) }

    # XXX Add this back once current staging deployed and so `rake
    # alces:data:import_and_migrate_production` should succeed with this set
    # (failing right now due to multiple Cluster data migrations since last
    # deploy).
    # it { is_expected.to validate_presence_of(:motd) }

    context 'when managed cluster' do
      subject do
        create(:managed_cluster)
      end

      context 'with managed node' do
        before :each do
          create(:managed_component, cluster: subject)
        end

        it { is_expected.to be_valid }
      end

      context 'with advice node' do
        before :each do
          create(:advice_component, cluster: subject)
        end

        it { is_expected.to be_valid }
      end
    end

    context 'when advice cluster' do
      subject do
        create(:advice_cluster)
      end

      context 'with managed node' do
        before :each do
          create(:managed_component, cluster: subject)
          subject.reload
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            base: [/advice Cluster cannot be associated with managed Components/]
          )
        end
      end

      context 'with advice node' do
        before :each do
          create(:advice_component, cluster: subject)
        end

        it { is_expected.to be_valid }
      end
    end
  end

  describe '#case_form_json' do
    subject do
      create(
        :cluster,
        id: 1,
        name: 'Some Cluster',
        support_type: :managed,
        charging_info: '£1000',
        motd: 'Some MOTD',
      ).tap do |cluster|
        cluster.components = [create(:component, cluster: cluster)]
        cluster.services = [create(:service, cluster: cluster)]
        cluster.credit_deposits = [create(:credit_deposit, amount: 20)]
        cluster.cases = [
          create(:case, credit_charge: create(:credit_charge, amount: 3))
        ]
      end
    end

    it 'gives correct JSON' do
      text_helper = Class.new do
        include ActionView::Helpers::TextHelper
      end.new

      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Some Cluster',
        components: subject.components.map(&:case_form_json),
        services: subject.services.map(&:case_form_json),
        supportType: 'managed',
        chargingInfo: '£1000',
        credits: 17, # Calculated by `credits` method as deposits - charges.
        motd: 'Some MOTD',
        motdHtml: text_helper.simple_format('Some MOTD')
      )
    end
  end

  describe '#managed_components' do
    subject do
      create(:cluster, support_type: 'managed') do |cluster|
        3.times { create(:component, cluster: cluster, support_type: 'inherit') }
        create(:component, cluster: cluster, support_type: 'managed')
        create(:component, cluster: cluster, support_type: 'advice')
      end
    end

    it 'returns all managed cluster components for cluster' do
      result = subject.managed_components
      expect(result).to all be_a(Component)
      expect(result.length).to be 4
    end
  end

  describe '#advice_components' do
    subject do
      create(:cluster, support_type: 'advice') do |cluster|
        4.times { create(:component, cluster: cluster, support_type: 'inherit') }
        create(:component, cluster: cluster, support_type: 'managed')
        create(:component, cluster: cluster, support_type: 'advice')
        cluster.reload
      end
    end

    it 'returns all advice cluster components for cluster' do
      result = subject.advice_components
      expect(result).to all be_a(Component)
      expect(result.length).to eq 5
    end
  end

  context 'cluster document tests' do
    subject { create(:cluster, name: 'Some Cluster', site: site) }
    let :site { create(:site, name: 'The Site') }

    before :each do
      ENV['AWS_DOCUMENTS_PREFIX'] = 'test-documents'
    end

    describe '#documents_path' do
      it 'returns correct path' do
        expect(subject.documents_path).to eq 'test-documents/the-site/some-cluster'
      end
    end

    describe '#documents' do
      it 'returns needed data for each Cluster document' do
        VCR.use_cassette(VcrCassettes::S3_READ_DOCUMENTS) do |cassette|
          Development::Utils.upload_document_fixtures_for(subject) if cassette.recording?

          documents = subject.documents

          # `upload_document_fixtures_for` will upload 'folder' objects (S3
          # doesn't have real folders but empty objects ending in `/` are
          # normally displayed that way) for directories (as this is equivalent
          # behaviour to AWS web interface), but `Cluster.documents` should
          # only retrieve the non-'folder' objects.
          expect(documents.length).to eq 3

          expect(documents.first.name).to eq 'Alces+Flight+on+AWS.pdf'
          expect(documents.first.url).to match(/https:\/\/.*#{CGI.escape("Alces+Flight+on+AWS.pdf")}.*/)

          # Loads document within 'folder' with folder name included in
          # Document name.
          expect(documents.last.name).to match(/nested\/\S+.pdf/)
        end
      end
    end
  end

  describe 'creation' do
    let! :automatic_service_types do
      ['User Management', 'Emotional Support'].map do |name|
        create(:automatic_service_type, name: name)
      end
    end

    it 'creates associated service for each existing automatic service type' do
      cluster = create(:cluster)

      cluster_service_names = cluster.services.map(&:name)
      expect(cluster_service_names).to eq(automatic_service_types.map(&:name))

      cluster_service_types = cluster.services.map(&:service_type)
      expect(cluster_service_types).to eq(automatic_service_types)
    end
  end

  describe '#component_groups_by_type' do
    subject do
      create(:cluster).tap do |cluster|

        # 2 groups of servers.
        server_make = create(:component_make, component_type: server_component_type)
        cluster.component_groups.create!(
          name: 'Node group',
          component_make: server_make,
          genders_host_range: 'node[01-03]',
        )
        cluster.component_groups.create!(
          name: 'Other node group',
          component_make: server_make,
          genders_host_range: 'othernodes[01-02]',
        )

        another_make = create(:component_make, component_type: another_component_type)
        cluster.component_groups.create!(
          name: 'Another group',
          component_make: another_make,
        ).tap do |group|
          group.components.create!(
            name: 'Single component'
          )
        end
      end.component_groups_by_type
    end

    let! :server_component_type do
      create(:component_type, name: 'Server', ordering: 2)
    end
    let! :another_component_type do
      create(:component_type, name: 'Another Type', ordering: 1)
    end
    let! :unused_component_type do
      create(:component_type, name: 'Unused')
    end

    it "returns cluster's component groups, with intermediate type-related object" do
      server_group = subject.find {|type| type.name == 'Server'}
      expect(server_group.component_groups.length).to eq 2

      node_group = server_group.component_groups.first
      expect(node_group.name).to eq 'Node group'
      expect(node_group.components.length).to eq 3
    end

    it 'includes component types that has some components for, ordered by ordering' do
      type_names = subject.map(&:name)
      expect(type_names).to eq(['Another Type', 'Server'])
    end
  end

  describe '#credits' do
    subject do
      create(:cluster).tap do |cluster|
        create(:credit_deposit, cluster: cluster, amount: 20)
        create(:credit_deposit, cluster: cluster, amount: 2)

        create(:case, cluster: cluster).tap do |case_|
          create(:credit_charge, case: case_, amount: 5)
        end

        create(:case, cluster: cluster).tap do |case_|
          create(:credit_charge, case: case_, amount: 2)
        end

        # Case without CreditCharge; should not effect total credits.
        create(:case, cluster: cluster)
      end.credits
    end

    it { is_expected.to eq 15 }
  end

  describe '#unfinished_related_maintenance_windows' do
    subject { create(:cluster) }

    it 'gives unfinished maintenance windows for Cluster and parts' do
      create(:requested_maintenance_window, cluster: subject, id: 1)
      create(:confirmed_maintenance_window, cluster: subject, id: 2)
      create(:ended_maintenance_window, cluster: subject, id: 3)

      component = create(:component, cluster: subject)
      create(:requested_maintenance_window, component: component, id: 4)
      create(:confirmed_maintenance_window, component: component, id: 5)
      create(:ended_maintenance_window, component: component, id: 6)

      resulting_window_ids = subject.unfinished_related_maintenance_windows.map(&:id)

      expect(resulting_window_ids).to match_array([1, 2, 4, 5])
    end

    it 'gives maintenance windows with newest first' do
      create(:requested_maintenance_window, cluster: subject, id: 1, created_at: 2.days.ago)
      create(:confirmed_maintenance_window, cluster: subject, id: 2, created_at: 1.day.ago)

      resulting_window_ids = subject.unfinished_related_maintenance_windows.map(&:id)

      expect(resulting_window_ids).to eq([2, 1])
    end
  end

  describe '#next_case_index' do
    subject { create(:cluster) }

    it 'gives a sequence of case indices starting with 1' do
      results = []
      results << subject.next_case_index
      results << subject.next_case_index
      results << subject.next_case_index

      expect(results).to eq [1, 2, 3]
    end
  end
end
