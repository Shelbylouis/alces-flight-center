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
