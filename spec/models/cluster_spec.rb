require 'rails_helper'

RSpec.describe Cluster, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_column'

  describe '#valid?' do
    subject { create(:cluster) }

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

  describe '#unfinished_related_maintenance_windows' do
    subject { create(:cluster) }

    it 'gives unfinished maintenance windows for Cluster and parts' do
      create(:requested_maintenance_window, clusters: [subject], id: 1)
      create(:confirmed_maintenance_window, clusters: [subject], id: 2)
      create(:ended_maintenance_window, clusters: [subject], id: 3)

      component = create(:component, cluster: subject)
      create(:requested_maintenance_window, components: [component], id: 4)
      create(:confirmed_maintenance_window, components: [component], id: 5)
      create(:ended_maintenance_window, components: [component], id: 6)

      resulting_window_ids = subject.unfinished_related_maintenance_windows.map(&:id)

      expect(resulting_window_ids).to match_array([1, 2, 4, 5])
    end

    it 'gives maintenance windows with newest first' do
      create(:requested_maintenance_window, clusters: [subject], id: 1, created_at: 2.days.ago)
      create(:confirmed_maintenance_window, clusters: [subject], id: 2, created_at: 1.day.ago)

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

  describe 'support credits' do
    subject { create(:cluster) }

    let(:admin) { create(:admin) }

    it 'is zero with no deposits or chargeable cases' do
      expect(subject.credit_balance).to eq 0
    end

    it 'calculates balance by summing deposits with charges on cases' do
      create(:credit_deposit, cluster: subject, amount: 36)
      create(:credit_deposit, cluster: subject, amount: 6)

      expect(subject.credit_balance).to eq 42

      create(:closed_case, cluster: subject, credit_charge: build(:credit_charge, amount: 12))
      create(:closed_case, cluster: subject, credit_charge: build(:credit_charge, amount: 6))
      create(:closed_case, cluster: subject, credit_charge: build(:credit_charge, amount: 3))

      expect(subject.credit_balance).to eq 21
    end

    it 'allows a negative balance' do
      create(:closed_case, cluster: subject, credit_charge: build(:credit_charge, amount: 12))
      expect(subject.credit_balance).to eq -12
    end
  end

  describe 'service plans' do
    include ActiveSupport::Testing::TimeHelpers

    let(:cluster) { create(:cluster) }

    let!(:plan_1) {
      create(
        :service_plan,
        cluster: cluster,
        start_date: '2018-01-01',
        end_date: '2018-08-31'
      )
    }

    let!(:plan_2) {
      create(
        :service_plan,
        cluster: cluster,
        start_date: '2018-09-05',
        end_date: '2019-04-30'
      )
    }

    it 'locates current plan' do
      travel_to Time.zone.local(2017, 12, 30) do
        expect(cluster.current_service_plan).to eq nil
      end
      travel_to Time.zone.local(2018, 1, 1) do
        expect(cluster.current_service_plan).to eq plan_1
      end
      travel_to Time.zone.local(2018, 8, 31) do
        expect(cluster.current_service_plan).to eq plan_1
      end
      travel_to Time.zone.local(2018, 9, 1) do
        expect(cluster.current_service_plan).to eq nil
      end
      travel_to Time.zone.local(2018, 9, 4) do
        expect(cluster.current_service_plan).to eq nil
      end
      travel_to Time.zone.local(2018, 9, 5) do
        expect(cluster.current_service_plan).to eq plan_2
      end
      travel_to Time.zone.local(2019, 4, 30) do
        expect(cluster.current_service_plan).to eq plan_2
      end
      travel_to Time.zone.local(2019, 5, 1) do
        expect(cluster.current_service_plan).to eq nil
      end
    end

    it 'locates previous plan' do
      travel_to Time.zone.local(2017, 12, 30) do
        expect(cluster.previous_service_plan).to eq nil
      end
      travel_to Time.zone.local(2018, 1, 1) do
        expect(cluster.previous_service_plan).to eq nil
      end
      travel_to Time.zone.local(2018, 8, 31) do
        expect(cluster.previous_service_plan).to eq nil
      end
      travel_to Time.zone.local(2018, 9, 1) do
        expect(cluster.previous_service_plan).to eq plan_1
      end
      travel_to Time.zone.local(2018, 9, 4) do
        expect(cluster.previous_service_plan).to eq plan_1
      end
      travel_to Time.zone.local(2018, 9, 5) do
        expect(cluster.previous_service_plan).to eq plan_1
      end
      travel_to Time.zone.local(2019, 4, 30) do
        expect(cluster.previous_service_plan).to eq plan_1
      end
      travel_to Time.zone.local(2019, 5, 1) do
        expect(cluster.previous_service_plan).to eq plan_2
      end
    end

    it 'identifies service plans covering a date range' do
      expect(cluster.service_plans_covering('2018-01-01', '2019-05-01'))
        .to eq [plan_1, plan_2]

      expect(cluster.service_plans_covering('2018-02-01', '2018-02-28'))
        .to eq [plan_1]

      expect(cluster.service_plans_covering('2018-06-01', '2018-09-30'))
        .to eq [plan_1, plan_2]
    end
  end
end
