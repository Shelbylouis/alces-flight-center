require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#create' do
    it 'only raises RecordInvalid when no Cluster' do
      # Previously raised DelegationError as tried to use Cluster which wasn't
      # present.
      expect do
        create(:case, cluster: nil)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'RT ticket creation on Case creation' do
    subject do
      build(
        :case,
        cluster: cluster,
        issue: issue,
        component: component,
        service: service,
        user: requestor,
        details: <<-EOF.strip_heredoc
          Oh no
          my node
          is broken
        EOF
      )
    end

    let :requestor do
      create(:user, name: 'Some User', email: 'someuser@somecluster.com')
    end

    let :site do
      create(:site)
    end

    let :another_user do
      create(:user, site: site, email: 'another.user@somecluster.com' )
    end

    let :additional_contact do
      create(
        :additional_contact,
        site: site,
        email: 'mailing-list@somecluster.com'
      )
    end

    let :issue do
      create(
        :issue,
        name: 'Crashed node',
        requires_component: requires_component,
        requires_service: requires_service,
        case_category: case_category
      )
    end

    let :requires_component { true }
    let :requires_service { true }

    let :case_category { create(:case_category, name: 'Hardware issue') }
    let :cluster { create(:cluster, site: site, name: 'somecluster') }
    let :component { create(:component, name: 'node01', cluster: cluster) }
    let :service { create(:service, name: 'Some service', cluster: cluster) }
    let :request_tracker { described_class.send(:request_tracker) }

    let :fake_rt_ticket { OpenStruct.new(id: 1234) }

    it 'creates rt ticket with correct properties' do
      expected_create_ticket_args = {
        requestor_email: requestor.email,

        # CC'ed emails should be those for all the site contacts and additional
        # contacts, apart from the requestor.
        cc: [another_user.email, additional_contact.email],

        subject: 'Alces Flight Center ticket: somecluster - Crashed node',
        text: <<-EOF.strip_heredoc
          Cluster: somecluster
          Case category: Hardware issue
          Issue: Crashed node
          Associated component: node01
          Associated service: Some service
          Details: Oh no
           my node
           is broken
        EOF
      }

      expect(request_tracker).to receive(:create_ticket).with(
        expected_create_ticket_args
      ).and_return(fake_rt_ticket)

      subject.save!
    end

    context 'when no associated component' do
      let :requires_component { false }
      let :component { nil }

      it 'does not include corresponding line in ticket text' do
        expect(request_tracker).to receive(:create_ticket).with(
          hash_excluding(
            text: /Associated component:/
          )
        ).and_return(fake_rt_ticket)

        subject.save!
      end
    end

    context 'when no associated service' do
      let :requires_service { false }
      let :service { nil }

      it 'does not include corresponding line in ticket text' do
        expect(request_tracker).to receive(:create_ticket).with(
          hash_excluding(
            text: /Associated service:/
          )
        ).and_return(fake_rt_ticket)

        subject.save!
      end
    end
  end

  describe '#mailto_url' do
    it 'creates correct mailto URL' do
      cluster = create(:cluster, name: 'somecluster')
      issue = create(:issue, name: 'New user request')
      rt_ticket_id = 12345

      support_case = described_class.new(
        cluster: cluster,
        issue: issue,
        rt_ticket_id: rt_ticket_id
      )

      expected_subject = CGI.escape(
        'RE: [helpdesk.alces-software.com #12345] Alces Flight Center ticket: somecluster - New user request'
      )
      expected_mailto_url = "mailto:support@alces-software.com?subject=#{expected_subject}"
      expect(support_case.mailto_url).to eq expected_mailto_url
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

  describe 'maintenance windows' do
    subject { create(:case_with_component) }

    describe '#request_maintenance_window!' do
      let :admin { create(:admin) }

      it 'creates new maintenance window' do
        subject.request_maintenance_window!(requestor: admin)

        maintenance_window = subject.maintenance_windows.first
        expect(maintenance_window.ended_at).to be nil
        expect(maintenance_window.user).to eq admin
      end
    end

    describe '#end_maintenance_window!' do
      context 'when no maintenance window' do
        it 'raises error' do
          expect do
            subject.end_maintenance_window!
          end.to raise_error(NoOpenMaintenanceWindowException)
        end
      end

      context 'when no open maintenance window' do
        before :each do
          create(:maintenance_window, case: subject, ended_at: 3.days.ago)
        end

        it 'raises error' do
          expect do
            subject.end_maintenance_window!
          end.to raise_error(NoOpenMaintenanceWindowException)
        end
      end

      context 'when open maintenance window' do
        before :each do
          create(:maintenance_window, case: subject)
        end

        it 'closes this maintenance window' do
          end_time = DateTime.new(2018)
          allow(DateTime).to receive(:current).and_return(end_time)

          subject.end_maintenance_window!

          expect(subject.maintenance_windows.length).to eq 1
          expect(subject.maintenance_windows.first.ended_at).to eq(end_time)
        end
      end
    end

    describe '#under_maintenance?' do
      context 'when has no maintenance windows' do
        it { is_expected.not_to be_under_maintenance }
      end

      context 'when has maintenance window without end' do
        before :each do
          create(:maintenance_window, case: subject, ended_at: 3.days.ago)
          create(:maintenance_window, case: subject)
        end

        it { is_expected.to be_under_maintenance }
      end

      context 'when has no maintenance windows without end' do
        before :each do
          create(:maintenance_window, case: subject, ended_at: 3.days.ago)
          create(:maintenance_window, case: subject, ended_at: 5.hours.ago)
        end

        it { is_expected.not_to be_under_maintenance }
      end
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
end
