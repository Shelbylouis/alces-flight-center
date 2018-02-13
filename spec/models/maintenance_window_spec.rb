require 'rails_helper'

RSpec.describe MaintenanceWindow, type: :model do
  describe '#valid?' do
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

  describe 'states' do
    it 'is initially in requested state' do
      window = create(:maintenance_window)

      expect(window.state).to eq 'requested'
    end

    context 'when requested' do
      subject { create(:maintenance_window, state: :requested) }

      it 'should not have confirmed_by set' do
        expect(subject).to be_valid
        subject.confirmed_by = create(:user)

        expect(subject).not_to be_valid
      end

      it 'should not have ended_at set' do
        expect(subject).to be_valid
        subject.ended_at = DateTime.current

        expect(subject).not_to be_valid
      end

      it 'can be confirmed by user' do
        user = create(:user)
        subject.confirm!(user)

        expect(subject).to be_confirmed
        expect(subject.confirmed_by).to eq(user)
      end
    end

    context 'when confirmed' do
      subject do
        create(
          :maintenance_window,
          state: :confirmed,
          confirmed_by: create(:user)
        )
      end

      it 'should have confirmed_by set' do
        expect(subject).to be_valid
        subject.confirmed_by = nil

        expect(subject).not_to be_valid
      end

      it 'should not have ended_at set' do
        expect(subject).to be_valid
        subject.ended_at = DateTime.current

        expect(subject).not_to be_valid
      end

      it 'can be ended by admin' do
        now = DateTime.current
        allow(DateTime).to receive(:current).and_return(now)
        admin = create(:admin)
        subject.end!(admin)

        expect(subject).to be_ended
        expect(subject.ended_at).to eq now
      end
    end

    context 'when ended' do
      subject do
        create(
          :maintenance_window,
          state: :ended,
          confirmed_by: create(:user),
          ended_at: DateTime.current
        )
      end

      it 'should have confirmed_by set' do
        expect(subject).to be_valid
        subject.confirmed_by = nil

        expect(subject).not_to be_valid
      end

      it 'should have ended_at set' do
        expect(subject).to be_valid
        subject.ended_at = nil

        expect(subject).not_to be_valid
      end
    end
  end

  describe '#awaiting_confirmation?' do
    context 'when unconfirmed' do
      subject { create(:unconfirmed_maintenance_window) }

      it { is_expected.to be_awaiting_confirmation }
    end

    context 'when confirmed and not ended' do
      subject { create(:confirmed_maintenance_window) }

      it { is_expected.not_to be_awaiting_confirmation }
    end

    context 'when ended' do
      subject { create(:closed_maintenance_window) }

      it { is_expected.not_to be_awaiting_confirmation }
    end
  end

  describe '#under_maintenance?' do
    context 'when unconfirmed' do
      subject { create(:unconfirmed_maintenance_window) }

      it { is_expected.not_to be_under_maintenance }
    end

    context 'when confirmed and not ended' do
      subject { create(:confirmed_maintenance_window) }

      it { is_expected.to be_under_maintenance }
    end

    context 'when ended' do
      subject { create(:closed_maintenance_window) }

      it { is_expected.not_to be_under_maintenance }
    end
  end

  describe '#ended?' do
    context 'when not ended' do
      subject { create(:confirmed_maintenance_window) }

      it { is_expected.not_to be_ended }
    end

    context 'when ended' do
      subject { create(:closed_maintenance_window) }

      it { is_expected.to be_ended }
    end
  end
end
