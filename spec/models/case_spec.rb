require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#valid?' do
    subject do
      build(
        :case,
        issue: issue,
        cluster: cluster,
        component: component
      )
    end
    let :cluster { create(:cluster) }
    let :component { nil }

    context 'when issue does not require component' do
      let :issue { create(:issue, requires_component: false) }

      context 'when not associated with component' do
        it { is_expected.to be_valid }
      end

      context 'when associated with component' do
        let :component { create(:component) }

        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(component: [/does not require a component/])
        end
      end
    end

    context 'when issue requires component' do
      let :issue { create(:issue, requires_component: true) }

      context 'when not associated with component' do
        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(component: [/requires a component/])
        end
      end

      context 'when associated with component that is part of associated cluster' do
        let :component { create(:component, cluster: cluster) }
        it { is_expected.to be_valid }
      end

      context 'when associated with component that is not part of associated cluster' do
        let :component { create(:component, cluster: create(:cluster)) }
        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(component: [/not part of given cluster/])
        end
      end
    end
  end

  describe '#create_rt_ticket' do
    subject do
      user = create(:user, name: 'Some User', email: requestor_email)

      create(:case,
        cluster: cluster,
        issue: issue,
        component: component,
        user: user,
        details: <<-EOF.strip_heredoc
          Oh no
          my node
          is broken
        EOF
      )
    end

    let :issue { create(:issue, name: 'Crashed node', requires_component: true, case_category: case_category) }
    let :case_category { create(:case_category, name: 'Hardware issue') }
    let :cluster { create(:cluster, name: 'somecluster') }
    let :component { create(:component, name: 'node01', cluster: cluster) }
    let :requestor_email { 'someuser@somecluster.com' }
    let :request_tracker { subject.send(:request_tracker) }

    it 'creates rt ticket with correct properties' do
      expected_create_ticket_args = {
        requestor_email: requestor_email,
        subject: 'Alces Flight Center ticket: somecluster - Crashed node',
        text: <<-EOF.strip_heredoc
          Cluster: somecluster
          Case category: Hardware issue
          Issue: Crashed node
          Associated component: node01
          Details: Oh no
           my node
           is broken
        EOF
      }

      expect(request_tracker).to receive(:create_ticket).with(
        expected_create_ticket_args
      ).and_return(
        OpenStruct.new(id: :fake_ticket_id)
      )

      subject.create_rt_ticket
    end

    context 'when no associated component' do
      let :issue { create(:issue, requires_component: false) }
      let :component { nil }

      it 'does not include corresponding line in ticket text' do
        expect(request_tracker).to receive(:create_ticket).with(
          hash_excluding(
            text: /Associated component:/
          )
        ).and_return(
          OpenStruct.new(id: :fake_ticket_id)
        )

        subject.create_rt_ticket
      end
    end
  end

  describe '#mailto_url' do
    it 'creates correct mailto URL' do
      cluster = create(:cluster, name: 'somecluster')
      issue = create(:issue, name:  'New user request')
      rt_ticket_id = 12345

      support_case = described_class.new(
        cluster: cluster,
        issue: issue,
        rt_ticket_id: rt_ticket_id
      )

      expected_subject = URI.escape(
        'RE: [helpdesk.alces-software.com #12345] Alces Flight Center ticket: somecluster - New user request'
      )
      expected_mailto_url = "mailto:support@alces-software.com?subject=#{expected_subject}"
      expect(support_case.mailto_url).to eq expected_mailto_url
    end
  end
end
