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

    it 'saves generated ticket token to later use in mailto_url' do
      subject.save!
      created_ticket_token = subject.token
      expect(created_ticket_token).to match(random_token_regex)
      subject.reload

      expect(subject.mailto_url).to include(created_ticket_token)
    end
  end

  describe '#active' do
    it 'returns all open Cases' do
      create(:case, subject: 'one', state: 'open')
      create(:case, subject: 'two', state: 'resolved')
      create(:case, subject: 'three', state: 'archived')
      create(:case, subject: 'four', state: 'open')

      active_cases = Case.active

      expect(active_cases.map(&:subject)).to match_array(['one', 'four'])
    end
  end

  describe '#mailto_url' do
    it 'creates correct mailto URL' do
      cluster = create(:cluster, name: 'somecluster')

      support_case = create(:case, cluster: cluster, subject: 'somesubject', rt_ticket_id: 12345)

      expected_subject =
        /RE: \[helpdesk\.alces-software\.com #12345\] somecluster: somesubject \[#{random_token_regex}\]/
      expected_mailto_url = /mailto:support@alces-software\.com\?subject=#{expected_subject}/
      expect(support_case.mailto_url).to match expected_mailto_url
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
end
