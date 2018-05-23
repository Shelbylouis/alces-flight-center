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

      context 'with managed service' do
        before :each do
          create(:managed_service, cluster: subject)
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

      context 'with managed service' do
        before :each do
          create(:managed_service, cluster: subject)
          subject.reload
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            base: [/advice Cluster cannot be associated with managed Services/]
          )
        end
      end
    end
  end

  context 'cluster document tests' do
    subject { create(:cluster, name: 'Some Cluster', site: site) }
    let(:site) { create(:site, name: 'The Site') }

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

          # This is the one place we actually want the original method to be called,
          # so here we override our default return value of [] (set in spec_helper).
          allow_any_instance_of(Cluster).to receive(:documents).and_call_original

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

  describe '#available_component_group_types' do
    subject do
      create(:cluster).tap do |cluster|

        server_make = create(
          :component_make,
          component_type: server_component_type
        )
        cluster.component_groups.create!(
          name: 'Node group',
          component_make: server_make
        )

        another_make = create(
          :component_make,
          component_type: another_component_type
        )
        cluster.component_groups.create!(
          name: 'Another group',
          component_make: another_make
        )

        yet_another_make = create(
          :component_make,
          component_type: yet_another_component_type
        )
        cluster.component_groups.create!(
          name: 'Yet another group',
          component_make: yet_another_make
        )
      end.available_component_group_types
    end

    let! :server_component_type do
      create(:component_type, name: 'Server', ordering: 2)
    end
    let! :another_component_type do
      create(:component_type, name: 'Another Type', ordering: 1)
    end
    let! :yet_another_component_type do
      create(:component_type, name: 'Yet Another Type', ordering: 4)
    end

    it 'returns the component types' do
      expect(subject).to eq(['Another Type', 'Server', 'Yet Another Type'])
    end
  end

  describe '#component_group_types' do
    subject do
    end
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
