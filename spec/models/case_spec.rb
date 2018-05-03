require 'rails_helper'

RSpec.describe Case, type: :model do
  let :random_token_regex { /[A-Z][0-9][A-Z][0-9][A-Z]/ }

  describe '#valid?' do
    subject { create(:case) }

    it { is_expected.to validate_presence_of(:fields) }
    it { is_expected.to validate_presence_of(:tier_level) }

    it do
      is_expected.to validate_numericality_of(:tier_level)
        .only_integer
        .is_greater_than_or_equal_to(1)
        .is_less_than_or_equal_to(3)
    end
  end

  describe '#create' do
    it 'only raises RecordInvalid when no Cluster' do
      # Previously raised DelegationError as tried to use Cluster which wasn't
      # present.
      expect do
        create(:case, cluster: nil)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'Cluster assignment on Case initialize' do
    it 'assigns Cluster appropriately when only associated with Component' do
      component = create(:component)

      support_case = Case.new(
        component: component,
        issue: create(:issue_requiring_component),
        cluster: nil
      )

      expect(support_case.cluster).to eq(component.cluster)
    end

    it 'assigns Cluster appropriately when only associated with Service' do
      service = create(:service)

      support_case = Case.new(
        service: service,
        issue: create(:issue_requiring_service),
        cluster: nil
      )


      expect(support_case.cluster).to eq(service.cluster)
    end

    it 'does not change Cluster if already present' do
      cluster = create(:cluster)

      # Don't use create otherwise test will fail as validation will fail.
      support_case = build(
        :case,
        service: create(:service),
        issue: create(:issue_requiring_service),
        cluster: cluster
      )
      support_case.save

      expect(support_case.cluster).to eq cluster
    end
  end

  describe 'subject generation on Case creation' do
    it 'assigns subject to issue default if none given' do
      issue = create(:issue, name: 'issue_name')
      support_case = create(:case, issue: issue)

      expect(support_case.subject).to eq(issue.default_subject)
    end

    it 'assigns subject to given value if given' do
      support_case = create(:case, subject: 'some_subject')
      support_case.reload

      expect(support_case.subject).to eq('some_subject')
    end
  end


  describe 'Email creation on Case creation' do
    subject do
      build(:case)
    end

    let :stub_mail do
      obj = double
      expect(obj).to receive(:deliver_later)
      obj
    end

    it 'sends an email' do
      # To find out what email it sends, see spec/mailers/case_mailer_spec.rb
      expect(CaseMailer).to receive(:new_case).with(
        subject
      ).and_return(stub_mail)

      subject.save!
    end

    it 'saves generated token' do
      subject.save!
      generated_token = subject.token
      expect(generated_token).to match(random_token_regex)
      subject.reload

      expect(subject.token).to eq(generated_token)
    end
  end

  describe 'Email creation on assignee change' do

    let(:initial_assignee) { nil }
    let(:site) { create(:site) }
    let(:cluster) { create(:cluster, site: site) }

    subject do
      create(:case, assignee: initial_assignee, cluster: cluster)
    end

    let :stub_mail do
      obj = double
      expect(obj).to receive(:deliver_later)
      obj
    end

    context 'with no previous assignee' do
      it 'sends an email' do
        assignee = create(:admin)
        subject.assignee = assignee

        expect(CaseMailer).to receive(:change_assignee).with(
          subject,
          assignee
        ).and_return(stub_mail)

        subject.save!
      end
    end

    context 'with a previous assignee' do
      let(:initial_assignee) { create(:user, site: site) }
      it 'sends an email' do
        assignee = create(:admin)
        subject.assignee = assignee

        expect(CaseMailer).to receive(:change_assignee).with(
          subject,
          assignee
        ).and_return(stub_mail)

        subject.save!
      end
    end

    context 'when being de-assigned' do
      let(:initial_assignee) { create(:user, site: site) }
      it 'does not send an email' do
        subject.assignee = nil

        expect(CaseMailer).not_to receive(:change_assignee)

        subject.save!
      end
    end
  end

  describe '#active' do
    it 'returns all open Cases' do
      create(:case, subject: 'one', state: 'open')
      create(:case, subject: 'two', state: 'resolved')
      create(:case, subject: 'three', state: 'closed')
      create(:case, subject: 'four', state: 'open')

      active_cases = Case.active

      expect(active_cases.map(&:subject)).to match_array(['one', 'four'])
    end
  end

  describe '#requires_credit_charge?' do
    let :support_case do
      create(
        :case,
        issue: issue,
        last_known_ticket_status: last_known_ticket_status
      )
    end

    subject { support_case.requires_credit_charge? }

    context 'when Issue chargeable and ticket complete' do
      let :issue { create(:issue, chargeable: true) }
      let :last_known_ticket_status { 'resolved' }

      it { is_expected.to be true }

      context 'when Case already has credit charge associated' do
        before :each do
          create(:credit_charge, case: support_case)
          support_case.reload
        end

        it { is_expected.to be false }
      end
    end

    context 'when Issue chargeable and ticket incomplete' do
      let :issue { create(:issue, chargeable: true) }
      let :last_known_ticket_status { 'stalled' }

      it { is_expected.to be false }
    end

    context 'when Issue non-chargeable and ticket complete' do
      let :issue { create(:issue, chargeable: false) }
      let :last_known_ticket_status { 'resolved' }

      it { is_expected.to be false }
    end
  end

  describe '#associated_model' do
    context 'when Case with Component' do
      subject { create(:case_with_component) }

      it 'gives Component' do
        expect(subject.associated_model).to eq(subject.component)
      end
    end

    context 'when Case with Service' do
      subject { create(:case_with_service) }

      it 'gives Service' do
        expect(subject.associated_model).to eq(subject.service)
      end
    end

    context 'when Case with just Cluster' do
      subject { create(:case) }

      it 'gives Cluster' do
        expect(subject.associated_model).to eq(subject.cluster)
      end
    end
  end

  describe '#associated_model_type' do
    subject { create(:case_with_component).associated_model_type }
    it { is_expected.to eq 'component' }
  end

  describe '#email_properties' do
    let :site { create(:site) }

    let :requestor do
      create(:user, name: 'Some User', email: 'someuser@somecluster.com', site: site)
    end

    let :issue do
      create(
        :issue,
        name: 'Crashed node',
        requires_component: requires_component,
        requires_service: requires_service,
        category: category
      )
    end

    let(:requires_component) { true }
    let(:requires_service) { true }

    let(:category) { create(:category, name: 'Hardware issue') }
    let(:cluster) { create(:cluster, site: site, name: 'somecluster') }
    let(:component) { create(:component, name: 'node01', cluster: cluster) }
    let(:service) { create(:service, name: 'Some service', cluster: cluster) }

    let(:kase) {
      create(
        :case,
        created_at: Time.now,
        cluster: cluster,
        issue: issue,
        component: component,
        service: service,
        user: requestor,
        subject: 'my_subject',
        tier_level: 3,
        fields: [
          {name: 'field1', value: 'value1'},
          {name: 'field2', value: 'value2', optional: true},
        ]
      )
    }

    it 'includes all needed Case properties with values' do
      expected_properties = {
        Cluster: 'somecluster',
        Category: 'Hardware issue',
        Issue: 'Crashed node',
        'Associated component': 'node01',
        'Associated service': 'Some service',
        Tier: '3 (General Support)',
        Fields: {
          field1: 'value1',
          field2: 'value2',
        }
      }

      expect(kase.email_properties).to eq expected_properties
    end

    context 'when no associated component' do
      let(:requires_component) { false }
      let(:component) { nil }

      it 'does not include corresponding line' do
        expect(kase.email_properties).not_to include(:'Associated component')
      end
    end

    context 'when no associated service' do
      let(:requires_service) { false }
      let(:service) { nil }

      it 'does not include corresponding line' do
        expect(kase.email_properties).not_to include(:'Associated service')
      end
    end
  end

  describe '#consultancy?' do
    it 'returns true when tier_level == 3' do
      kase = create(:case, tier_level: 3)

      expect(kase).to be_consultancy
    end

    it 'returns false when tier_level < 3' do
      kase = create(:case, tier_level: 2)

      expect(kase).not_to be_consultancy
    end
  end

  describe '#display_id' do
    it "gives RT ticket ID with 'RT' prefix when RT ticket ID associated" do
      kase = create(:case, rt_ticket_id: 12345)

      expect(kase.display_id).to eq('RT12345')
    end

    it "gives cluster-specific unique ID when no RT ticket ID associated" do
      kase = create(:case)

      expect(kase.display_id).to eq("#{kase.cluster.shortcode}1")
      expect(kase.cluster.case_index).to eq 1
    end

    it 'doesn\'t use up a case_index when case is invalid' do

      cluster = create(:cluster)

      expect(cluster.case_index).to eq 0

      bad_case = build(:case, cluster: cluster, tier_level: 99)

      expect do
        bad_case.save!
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(cluster.case_index).to eq 0
    end
  end
end
