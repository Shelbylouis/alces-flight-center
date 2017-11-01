require 'rails_helper'

# Shared examples for a Case-part relationship, where a part:
# - is a class with a factory identified by `part_name`;
# - has a `support_type`;
# - has a `cluster`;
# - a Case may be required or forbidden from having a relationship with a part,
# depending on the `support_type` of both.
RSpec.shared_examples 'associated Cluster part validation' do |part_name|
  context "when issue requires #{part_name}" do
    before :each do
      requires_part_name = "requires_#{part_name}".to_sym
      issue_attributes.merge!(requires_part_name => true)
    end

    let :managed_part_name { "managed_#{part_name}" }
    let :advice_part_name { "advice_#{part_name}" }

    # Explicitly specify advice cluster to ensure only relying on part
    # `support_type`, in tests where this is relevant.
    let :cluster { create(:advice_cluster) }

    context "when not associated with #{part_name}" do
      it 'should be invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to include(part_name => [/requires a #{part_name}/])
      end
    end

    context "when associated with #{part_name} that is part of associated cluster" do
      let :part { create(part_name, cluster: cluster) }
      it { is_expected.to be_valid }
    end

    context "when associated with #{part_name} that is not part of associated cluster" do
      let :part { create(part_name, cluster: create(:cluster)) }
      it 'should be invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages).to include(part_name => [/not part of given cluster/])
      end
    end

    context 'when `managed` issue' do
      before :each do
        issue_attributes.merge!(support_type: :managed)
      end

      context "with `managed` #{part_name}" do
        let :part { create(managed_part_name, cluster: cluster) }
        it { is_expected.to be_valid }
      end

      context "with `advice` #{part_name}" do
        let :part { create(advice_part_name, cluster: cluster) }
        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(
            issue: [/is only available for fully managed #{part_name.to_s.pluralize}, but given #{part_name} is self-managed/]
          )
        end
      end
    end

    context 'when `advice` issue' do
      before :each do
        issue_attributes.merge!(support_type: :advice)
      end

      context "with `managed` #{part_name}" do
        let :part { create(managed_part_name, cluster: cluster) }
        it { is_expected.to be_valid }
      end

      context "with `advice` #{part_name}" do
        let :part { create(advice_part_name, cluster: cluster) }
        it { is_expected.to be_valid }
      end
    end

    context 'when `advice-only` issue' do
      before :each do
        issue_attributes.merge!(support_type: 'advice-only')
      end

      context "with `managed` #{part_name}" do
        let :part { create(managed_part_name, cluster: cluster) }
        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(
            issue: [/is only available for self-managed #{part_name.to_s.pluralize}, but given #{part_name} is fully managed/]
          )
        end
      end

      context "with `advice` #{part_name}" do
        let :part { create(advice_part_name, cluster: cluster) }
        it { is_expected.to be_valid }
      end
    end
  end
end


RSpec.describe Case, type: :model do
  describe '#valid?' do
    subject do
      attributes = {
        issue: issue,
        cluster: cluster,
        component: component,
        service: service
      }

      # If `part` is set, appropriately add Case attribute depending on `part`
      # class.
      if part
        case part
        when Component
          attributes[:component] = part
        when Service
          attributes[:service] = part
        else
          raise "Unknown part class: #{part.class}"
        end
      end

      build(:case, **attributes)
    end

    let :cluster { create(:cluster) }
    let :component { nil }
    let :service { nil }
    let :part { nil }

    let :issue { create(:issue, issue_attributes) }

    # Specify advice issue to avoid managed issue-related validations failing,
    # unless explicitly testing these.
    let :issue_attributes { attributes_for(:advice_issue) }

    include_examples 'associated Cluster part validation', :component
    include_examples 'associated Cluster part validation', :service

    context 'when issue does not require component or service' do
      before :each do
        issue_attributes.merge!(
          requires_component: false,
          requires_service: false
        )
      end

      context 'when not associated with component or service' do
        it { is_expected.to be_valid }
      end

      context 'when associated with component' do
        let :component { create(:component) }

        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(component: [/does not require a component/])
        end
      end

      context 'when associated with service' do
        let :service { create(:service) }

        it 'should be invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages).to include(service: [/does not require a service/])
        end
      end

      context 'when `managed` issue' do
        before :each do
          issue_attributes.merge!(support_type: :managed)
        end

        context 'with `managed` cluster' do
          let :cluster { create(:managed_cluster) }
          it { is_expected.to be_valid }
        end

        context 'with `advice` cluster' do
          let :cluster { create(:advice_cluster) }
          it 'should be invalid' do
            expect(subject).not_to be_valid
            expect(subject.errors.messages).to include(
              issue: [/is only available for fully managed clusters, but given cluster is self-managed/]
            )
          end
        end
      end

      context 'when `advice` issue' do
        before :each do
          issue_attributes.merge!(support_type: :advice)
        end

        context 'with `managed` cluster' do
          let :cluster { create(:managed_cluster) }
          it { is_expected.to be_valid }
        end

        context 'with `advice` cluster' do
          let :cluster { create(:advice_cluster) }
          it { is_expected.to be_valid }
        end
      end

      context 'when `advice-only` issue' do
        before :each do
          issue_attributes.merge!(support_type: 'advice-only')
        end

        context 'with `managed` cluster' do
          let :cluster { create(:managed_cluster) }
          it 'should be invalid' do
            expect(subject).not_to be_valid
            expect(subject.errors.messages).to include(
              issue: [/is only available for self-managed clusters, but given cluster is fully managed/]
            )
          end
        end

        context 'with `advice` cluster' do
          let :cluster { create(:advice_cluster) }
          it { is_expected.to be_valid }
        end
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

  describe '#create_rt_ticket' do
    subject do
      create(
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
    let :request_tracker { subject.send(:request_tracker) }

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
      ).and_return(
        OpenStruct.new(id: :fake_ticket_id)
      )

      subject.create_rt_ticket
    end

    context 'when no associated component' do
      let :requires_component { false }
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

    context 'when no associated service' do
      let :requires_service { false }
      let :service { nil }

      it 'does not include corresponding line in ticket text' do
        expect(request_tracker).to receive(:create_ticket).with(
          hash_excluding(
            text: /Associated service:/
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
end
