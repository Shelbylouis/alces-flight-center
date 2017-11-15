require 'rails_helper'

RSpec.describe Cluster, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_description'

  describe '#valid?' do
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
        support_type: :managed
      ).tap do |cluster|
        cluster.components = [create(:component, cluster: cluster)]
        cluster.services = [create(:service, cluster: cluster)]
      end
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Some Cluster',
        components: subject.components.map(&:case_form_json),
        services: subject.services.map(&:case_form_json),
        supportType: 'managed'
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
        VCR.use_cassette(VcrCassettes::S3_READ_DOCUMENTS) do
          Development::Utils.upload_document_fixtures_for(subject)

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
        cluster.component_groups.create!(
          name: 'Node group',
          component_type: server_component_type,
          genders_host_range: 'node[01-03]',
        )
        cluster.component_groups.create!(
          name: 'Other node group',
          component_type: server_component_type,
          genders_host_range: 'othernodes[01-02]',
        )

        cluster.component_groups.create!(
          name: 'Another group',
          component_type: another_component_type,
        ).tap do |group|
          group.components.create!(
            name: 'Single component'
          )
        end
      end.component_groups_by_type
    end

    let! :server_component_type do
      create(:component_type, name: 'Server')
    end
    let! :another_component_type do
      create(:component_type, name: 'Another Type')
    end
    let! :unused_component_type do
      create(:component_type, name: 'Unused')
    end

    it "returns cluster's component groups, with intermediate type-related object" do
      server_group = subject.first
      expect(server_group.name).to eq('Server')
      expect(server_group.component_groups.length).to eq 2

      node_group = server_group.component_groups.first
      expect(node_group.name).to eq 'Node group'
      expect(node_group.components.length).to eq 3
    end

    it 'only includes component types that cluster has some components for' do
      type_names = subject.map(&:name)
      expect(type_names).to eq(['Server', 'Another Type'])
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
end
