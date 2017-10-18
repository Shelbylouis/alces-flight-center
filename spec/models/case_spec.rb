require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#valid?' do
    context 'when case category does not require component' do
      let :case_category { create(:case_category, requires_component: false) }

      it 'passes if not associated with component' do
        support_case = build(
          :case,
          case_category: case_category
        )

        expect(support_case.valid?).to be true
      end

      it 'fails if associated with component' do
        support_case = build(
          :case,
          case_category: case_category,
          component: create(:component)
        )

        expect(support_case.valid?).to be false
        expect(support_case.errors.messages).to include(component: [/does not require a component/])
      end
    end

    context 'when case category requires component' do
      let :case_category { create(:case_category, requires_component: true) }
      let :cluster { create(:cluster) }
      let :component { create(:component, cluster: cluster) }

      it 'passes if associated with component' do
        support_case = build(
          :case,
          case_category: case_category,
          component: component,
          cluster: cluster
        )

        expect(support_case.valid?).to be true
      end

      it 'fails if not associated with component' do
        support_case = build(
          :case,
          case_category: case_category
        )

        expect(support_case.valid?).to be false
        expect(support_case.errors.messages).to include(component: [/requires a component/])
      end

      it 'passes if component part of associated cluster' do
        support_case = build(
          :case,
          case_category: case_category,
          component: component,
          cluster: cluster
        )

        expect(support_case.valid?).to be true
      end

      it 'fails if component not part of associated cluster' do
        another_cluster = create(:cluster)
        component = create(:component, cluster: another_cluster)
        support_case = build(
          :case,
          case_category: case_category,
          component: component,
          cluster: cluster
        )

        expect(support_case.valid?).to be false
        expect(support_case.errors.messages).to include(component: [/not part of given cluster/])
      end
    end
  end

  describe '#create_rt_ticket' do
    subject do
      # XXX Use FactoryGirl here.
      cluster = Cluster.new(name: 'somecluster')
      case_category = CaseCategory.new(name: 'Crashed node')
      user = User.new(
        name: 'Some User',
        email: requestor_email
      )

      described_class.new(
        cluster: cluster,
        case_category: case_category,
        component: component,
        user: user,
        details: <<-EOF.strip_heredoc
          Oh no
          my node
          is broken
        EOF
      )
    end

    let :component { Component.new(name: 'node01') }
    let :requestor_email { 'someuser@somecluster.com' }
    let :request_tracker { subject.send(:request_tracker) }

    it 'creates rt ticket with correct properties' do
      expected_create_ticket_args = {
        requestor_email: requestor_email,
        subject: 'Alces Flight Center ticket: somecluster - Crashed node',
        text: <<-EOF.strip_heredoc
          Cluster: somecluster
          Case category: Crashed node
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
      cluster = Cluster.new(name: 'somecluster')
      case_category = CaseCategory.new(name: 'New user request')
      rt_ticket_id = 12345

      support_case = described_class.new(
        cluster: cluster,
        case_category: case_category,
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
