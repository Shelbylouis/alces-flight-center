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

      context "with `managed` #{part_name} which is later switched to `advice`" do
        let :part { create(managed_part_name, cluster: cluster) }

        before :each do
          # Create Case which is initially valid.
          subject.save!

          # Update the part to one which would no longer be compatible with
          # given issue.
          part.update!(support_type: :advice)
        end

        it { is_expected.to be_valid }
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

      context "with `managed` cluster but `advice` #{part_name}" do
        let :cluster { create(:managed_cluster) }
        let :part { create(advice_part_name, cluster: cluster) }
        it { is_expected.to be_valid }
      end

      context "with `advice` #{part_name} which is later switched to `managed`" do
        let :part { create(advice_part_name, cluster: cluster) }

        before :each do
          # Create Case which is initially valid.
          subject.save!

          # Update the part to one which would no longer be compatible with
          # given issue.
          part.update!(support_type: :managed)
        end

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

    let :issue { create(:issue, **issue_attributes) }

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

        context "with `managed` cluster which is later switched to `advice`" do
          let :cluster { create(:managed_cluster) }

          before :each do
            # Create Case which is initially valid.
            subject.save!

            # Update the cluster to one which would no longer be compatible
            # with given issue.
            cluster.update!(support_type: :advice)
          end

          it { is_expected.to be_valid }
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

        context "with `advice` cluster which is later switched to `managed`" do
          let :cluster { create(:advice_cluster) }

          before :each do
            # Create Case which is initially valid.
            subject.save!

            # Update the cluster to one which would no longer be compatible with
            # given issue.
            cluster.update!(support_type: :managed)
          end

          it { is_expected.to be_valid }
        end
      end
    end

    context "when issue requires service of particular type" do
      let :issue do
        create(:issue, requires_service: true, service_type: service_type)
      end

      let :service_type do
        create(:service_type, name: 'File System')
      end

      context 'when associated with service of that type' do
        let :service do
          create(:service, cluster: cluster, service_type: service_type)
        end

        it { is_expected.to be_valid }
      end

      context 'when associated with service of a different type' do
        let :service do
          create(
            :service,
            cluster: cluster,
            service_type: create(:service_type, name: 'User Management')
          )
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to match(
            service: [/must be.*File System.*but.*User Management/]
          )
        end
      end
    end
  end
end
