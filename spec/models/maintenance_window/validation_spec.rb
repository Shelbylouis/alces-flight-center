require 'rails_helper'

RSpec.shared_examples 'it validates dates cannot be in the past' do |date_fields|
  # Fields which should otherwise be in the future can be in the past when in
  # these states, otherwise existing saved MaintenanceWindows would become
  # invalidated.
  valid_states = [:cancelled, :ended, :expired, :rejected, :started]

  let :legacy_migration_mode { false }

  valid_states.each do |state|
    context "when #{state}" do
      let :state { state }

      it { is_expected.to be_valid }
    end
  end

  other_states = MaintenanceWindow.possible_states - valid_states

  other_states.each do |state|
    context "when #{state}" do
      let :state { state }

      let :expected_errors do
        date_fields.map do |field|
          [field, ['cannot be in the past']]
        end.to_h
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to match(expected_errors)
      end
    end
  end

  context 'when `legacy_migration_mode` flag set on model' do
    let :legacy_migration_mode { true }

    # Should skip this validation and be valid in every state.
    MaintenanceWindow.possible_states.each do |state|
      context "when #{state}" do
        let :state { state }

        it { is_expected.to be_valid }
      end
    end
  end
end

RSpec.describe MaintenanceWindow, type: :model do
  describe '#valid?' do
    describe 'associated_model validations' do
      subject do
        build(
          :maintenance_window,
          cluster: cluster,
          component: component,
          service: service
        )
      end
      let :cluster { nil }
      let :component { nil }
      let :service { nil }

      context 'when single associated model given' do
        let :cluster { create(:cluster) }

        it { is_expected.to be_valid }
      end

      context 'when no associated model given' do
        it { is_expected.to be_invalid }
      end

      context 'when both Cluster and Component associated' do
        let :cluster { create(:cluster) }
        let :component { create(:component) }

        it { is_expected.to be_invalid }
      end

      context 'when both Cluster and Service associated' do
        let :cluster { create(:cluster) }
        let :service { create(:service) }

        it { is_expected.to be_invalid }
      end

      context 'when both Component and Service associated' do
        let :component { create(:component) }
        let :service { create(:service) }

        it { is_expected.to be_invalid }
      end
    end

    context 'after invalid transition' do
      subject { create(:maintenance_window) }

      before :each do
        subject.request!
      end

      it { is_expected.to be_invalid }
    end

    describe 'maintenance period validations' do
      it { is_expected.to validate_presence_of(:requested_start) }
      it { is_expected.to validate_presence_of(:requested_end) }

      it { is_expected.to validate_presence_of(:duration) }
      it { is_expected.to validate_numericality_of(:duration).is_greater_than(0) }

      context 'when requested_start after requested_end' do
        subject do
          build(
            :maintenance_window,
            requested_start: 2.days.from_now,
            requested_end: 1.days.from_now,
          )
        end

        it 'should be invalid' do
          expect(subject).to be_invalid
          expect(subject.errors.messages).to match(requested_end: ['must be after start'])
        end
      end

      context 'when requested_start and requested_end in past' do
        subject do
          build(
            :maintenance_window,
            state: state,
            requested_start: 2.days.ago,
            requested_end: 1.days.ago,
            legacy_migration_mode: legacy_migration_mode,
          )
        end

        it_behaves_like 'it validates dates cannot be in the past' , [:requested_start, :requested_end]
      end

      context 'when just requested_start in past' do
        subject do
          build(
            :maintenance_window,
            state: state,
            requested_start: 1.days.ago,
            requested_end: 1.days.from_now,
            legacy_migration_mode: legacy_migration_mode,
          )
        end

        it_behaves_like 'it validates dates cannot be in the past' , [:requested_start]
      end
    end
  end
end
