require 'rails_helper'

RSpec.describe 'Cluster credit deposits' do
  let(:site) { create(:site) }
  let(:cluster) { create(:cluster) }
  let(:user) { create(:user, site: site) }
  let(:admin) { create(:admin) }

  let(:params) {
    { cluster_id: cluster.id, credit_deposit: { amount: 4 } }
  }

  context 'as a non-admin' do
    it 'returns 404 when attempting to deposit' do
      post cluster_deposit_path(cluster, as: user), params: params
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'as an admin' do
    it 'allows a deposit' do
      post cluster_deposit_path(cluster, as: admin), params: params
      # Expect :found and not :ok since it redirects
      expect(response).to have_http_status(:found)
    end
  end
end
