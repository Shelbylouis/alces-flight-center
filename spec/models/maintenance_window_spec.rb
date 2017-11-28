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
end
