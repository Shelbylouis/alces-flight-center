require 'rails_helper'

RSpec.describe Case, type: :model do
  let(:random_token_regex) { /[A-Z][0-9][A-Z][0-9][A-Z]/ }

  it { is_expected.to have_one(:change_motd_request).autosave(true) }

  describe '#valid?' do
    subject { create(:case) }

    it { is_expected.to validate_presence_of(:tier_level) }
    it { is_expected.to have_one(:change_motd_request) }

    it do
      is_expected.to validate_numericality_of(:tier_level)
        .only_integer
        .is_greater_than_or_equal_to(1)
        .is_less_than_or_equal_to(4)
    end

    describe 'fields validation' do
      it { is_expected.to validate_presence_of(:fields) }

      context 'when has fields' do
        subject do
          build(:case, fields: [{type: 'input', name: 'Some field'}])
        end

        it { is_expected.to validate_absence_of(:change_motd_request) }
        it { is_expected.to be_valid }
      end

      context 'when has change_mode_request' do
        subject do
          build(
            :case,
            fields: nil,
            change_motd_request: build(:change_motd_request)
          )
        end

        it { is_expected.to validate_absence_of(:fields) }
        it { is_expected.to be_valid }
      end
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
        components: [component],
        issue: create(:issue_requiring_component),
        cluster: nil
      )

      expect(support_case.cluster).to eq(component.cluster)
    end

    it 'assigns Cluster appropriately when only associated with Service' do
      service = create(:service)

      support_case = Case.new(
        services: [service],
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
        services: [create(:service)],
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
      create(:open_case, subject: 'one')
      create(:resolved_case, subject: 'two')
      create(:closed_case, subject: 'three')
      create(:open_case, subject: 'four')

      active_cases = Case.active

      expect(active_cases.map(&:subject)).to match_array(['one', 'four'])
    end
  end

  describe '#email_properties' do
    let(:site) { create(:site) }

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

    let :fields do
      [
        {name: 'field1', value: 'value1'},
        {name: 'field2', value: 'value2', optional: true},
      ]
    end
    let(:change_motd_request) { nil }

    let(:kase) {
      create(
        :case,
        created_at: Time.now,
        cluster: cluster,
        issue: issue,
        components: component ? [component] : [],
        services: service ? [service] : [],
        user: requestor,
        subject: 'my_subject',
        tier_level: 3,
        fields: fields,
        change_motd_request: change_motd_request,
      )
    }

    it 'includes all needed Case properties with values' do
      expected_properties = {
        Cluster: 'somecluster',
        Category: 'Hardware issue',
        Issue: 'Crashed node',
        'Associated components': 'node01',
        'Associated services': 'Some service',
        Tier: '3 (General Support)',
        Fields: {
          field1: 'value1',
          field2: 'value2',
        }
      }

      expect(kase.email_properties).to eq expected_properties
    end

    context 'when no associated components' do
      let(:requires_component) { false }
      let(:component) { nil }

      it 'does not include corresponding line' do
        expect(kase.email_properties).not_to include(:'Associated components')
      end
    end

    context 'when no associated service' do
      let(:requires_service) { false }
      let(:service) { nil }

      it 'does not include corresponding line' do
        expect(kase.email_properties).not_to include(:'Associated services')
      end
    end

    context 'when Case has ChangeMotdRequest rather than fields' do
      let(:fields) { nil }

      let(:motd) { 'My new MOTD' }
      let :change_motd_request do
        build(:change_motd_request, motd: motd)
      end

      it 'includes requested MOTD and not fields' do
        expect(kase.email_properties).to include(:'Requested MOTD' => motd)
        expect(kase.email_properties).not_to include(:Fields)
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

  describe ':time_worked' do

    it 'can be changed when case is open' do
      kase = create(:open_case, time_worked:42)

      kase.time_worked = 48
      expect do
        kase.save!
      end.not_to raise_error
    end

    %w(resolved closed).each do |state|
      it "cannot be changed when case is #{state}" do
        kase = create("#{state}_case".to_sym, time_worked:42)

        kase.time_worked = 48
        expect do
          kase.save!
        end.to raise_error(ActiveRecord::RecordInvalid)
        expect(kase.errors.messages).to match({time_worked: ["must not be changed when case is #{state}"]})
      end
    end
  end

  describe '#tool_fields=' do
    subject do
      build(:case, fields: nil)
    end

    let :motd_tool_fields do
      {
        type: 'motd',
        motd: motd_field,
      }
    end
    let(:motd_field) { 'New MOTD' }


    it 'also works when keys are strings' do
      stringified_tool_fields = motd_tool_fields.deep_stringify_keys
      subject.tool_fields = stringified_tool_fields

      expect(subject.change_motd_request).not_to be_nil
    end

    context "when given hash with type field 'motd'" do
      it "builds ChangeMotdRequest from given 'motd' field" do
        subject.tool_fields = motd_tool_fields

        expect(subject.change_motd_request).not_to be_nil
        expect(subject.change_motd_request.motd).to eq motd_field
        expect(subject.change_motd_request).to be_valid
        # Should initially be unsaved, and should be saved iff the Case itself
        # is successfully saved.
        expect(subject.change_motd_request).not_to be_persisted
      end
    end

    context "when given hash with unknown type field" do
      it "raises error" do
        expect do
          subject.tool_fields = { type: 'foo' }
        end.to raise_error("Unknown type: 'foo'")
      end
    end
  end

  describe '#potential_assignees' do
    subject { kase.potential_assignees.map(&:name) }
    let(:kase) { create(:case) }

    it 'includes any admin' do
      create(:admin, name: 'some_admin')

      expect(subject).to include('some_admin')
    end

    it 'includes any contact for site of Case' do
      create(:contact, name: 'some_contact', site: kase.site)

      expect(subject).to include('some_contact')
    end

    it 'does not include unrelated contact' do
      create(:contact, name: 'some_contact')

      expect(subject).not_to include('some_contact')
    end

    it 'does not include viewer for site of Case' do
      create(:viewer, name: 'some_viewer', site: kase.site)

      expect(subject).not_to include('some_viewer')
    end
  end

  describe '#commenting_enabled_for?' do
    it 'returns inverse of what CaseCommenting#disabled? would give' do
      user = build_stubbed(:user)
      kase = build_stubbed(:case)
      stub_case_commenting = CaseCommenting.new(kase, user)
      allow(stub_case_commenting).to receive(:disabled?).and_return true
      allow(
        CaseCommenting
      ).to receive(:new).with(kase, user).and_return(stub_case_commenting)

      expect(kase.commenting_enabled_for?(user)).to eq(false)
    end
  end

  describe '#resolve!' do
    let(:kase) { build(:open_case, tier_level: 4) }

    it 'is unresolvable with an outstanding change request' do
      create(:change_request, case: kase, state: :awaiting_authorisation)

      expect(kase.resolvable?).to eq false

      expect do
        kase.resolve!
      end.to raise_error StateMachines::InvalidTransition

      expect(kase.errors.messages).to include(
        state: ['cannot be resolved with an open change request']
      )
    end
  end

  describe '#credit_charge' do
    it 'cannot have a charge less than that of an attached completed change request' do
      kase = build(:closed_case, tier_level: 4, credit_charge: build(:credit_charge, amount: 41))
      build(:change_request, case: kase, credit_charge: 42, state: 'completed')

      expect do
        kase.save!
      end.to raise_error ActiveRecord::RecordInvalid
      expect(kase.errors.messages).to include(
        credit_charge: ['cannot be less than attached CR charge of 42']
      )
    end

    it 'does not restrict charge of attached declined change request' do
      kase = build(:closed_case, tier_level: 4, credit_charge: build(:credit_charge, amount: 41))
      build(:change_request, case: kase, credit_charge: 42, state: 'declined')

      expect do
        kase.save!
      end.not_to raise_error
    end
  end

  describe '#change_request' do
    it 'cannot be present if tier_level is less than 4' do
      kase = build(:open_case, tier_level: 3)
      build(:change_request, case: kase)

      expect do
        kase.save!
      end.to raise_error ActiveRecord::RecordInvalid
      expect(kase.errors.messages).to include(
        change_request: ['must be blank']
      )
    end
    it 'must be present if tier_level is 4' do
      kase = build(:open_case, tier_level: 4)

      expect do
        kase.save!
      end.to raise_error ActiveRecord::RecordInvalid
      expect(kase.errors.messages).to include(
        change_request: ['can\'t be blank']
      )
    end
  end

  describe '#associations' do
    let(:site) { create(:site) }
    let(:cluster) { create(:cluster, site: site) }
    let(:component) { create(:component, name: 'node01', cluster: cluster) }
    let(:component_group) { create(:component_group, cluster: cluster) }
    let(:service) { create(:service, name: 'Some service', cluster: cluster) }

    context 'with all types of things associated' do
      subject do
        create(
            :open_case,
            components: [component],
            services: [service],
            component_groups: [component_group],
            cluster: cluster
        )
      end

      it 'lists associations in correct order' do
        expect(subject.associations).to eq [component_group, component, service]
      end
    end

    context 'with nothing associated' do
      subject do
        create(
            :open_case,
            components: [],
            services: [],
            component_groups: [],
            cluster: cluster
        )
      end

      it 'lists cluster as association' do
        expect(subject.associations).to eq [cluster]
      end
    end
  end
end
