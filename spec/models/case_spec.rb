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

    let :issue { create(:issue, issue_attributes) }

    # Specify advice issue to avoid managed issue-related validations failing,
    # unless explicitly testing these.
    let :issue_attributes { attributes_for(:advice_issue) }

    context 'when issue does not require component' do
      before :each do
        issue_attributes.merge!(requires_component: false)
      end

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

    context 'when issue requires component' do
      before :each do
        issue_attributes.merge!(requires_component: true)
      end

      # Explicitly specify advice cluster to ensure only relying on component
      # `support_type`, in tests where this is relevant.
      let :cluster { create(:advice_cluster) }

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

      context 'when `managed` issue' do
        before :each do
          issue_attributes.merge!(support_type: :managed)
        end

        context 'with `managed` component' do
          let :component { create(:managed_component, cluster: cluster) }
          it { is_expected.to be_valid }
        end

        context 'with `advice` component' do
          let :component { create(:advice_component, cluster: cluster) }
          it 'should be invalid' do
            expect(subject).not_to be_valid
            expect(subject.errors.messages).to include(
              issue: [/is only available for fully managed components, but given component is self-managed/]
            )
          end
        end
      end

      context 'when `advice` issue' do
        before :each do
          issue_attributes.merge!(support_type: :advice)
        end

        context 'with `managed` component' do
          let :component { create(:managed_component, cluster: cluster) }
          it { is_expected.to be_valid }
        end

        context 'with `advice` component' do
          let :component { create(:advice_component, cluster: cluster) }
          it { is_expected.to be_valid }
        end
      end

      context 'when `advice-only` issue' do
        before :each do
          issue_attributes.merge!(support_type: 'advice-only')
        end

        context 'with `managed` component' do
          let :component { create(:managed_component, cluster: cluster) }
          it 'should be invalid' do
            expect(subject).not_to be_valid
            expect(subject.errors.messages).to include(
              issue: [/is only available for self-managed components, but given component is fully managed/]
            )
          end
        end

        context 'with `advice` component' do
          let :component { create(:advice_component, cluster: cluster) }
          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '#create_rt_ticket' do
    subject do
      create(
        :case,
        cluster: cluster,
        issue: issue,
        component: component,
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
        requires_component: true,
        case_category: case_category
      )
    end

    let :case_category { create(:case_category, name: 'Hardware issue') }
    let :cluster { create(:cluster, site: site, name: 'somecluster') }
    let :component { create(:component, name: 'node01', cluster: cluster) }
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
