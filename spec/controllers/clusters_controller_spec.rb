require 'rails_helper'

RSpec.describe ClustersController, type: :controller do

  let(:site) { create(:site) }
  let(:user) { create(:contact, site: site) }
  let(:admin) { create(:admin) }
  let!(:cluster) { create(:cluster, site: site, name: 'Some Cluster') }

  describe 'POST #deposit' do

    let(:params) {
      { cluster_id: cluster, credit_deposit: { amount: 4 } }
    }

    context 'as an admin' do

      before(:each) do
        sign_in_as(admin)
      end

      it 'should allow credit deposits' do

        expect(cluster.credit_balance).to eq 0

        post :deposit, params: params

        expect(response).to have_http_status(:found)
        expect(response.headers['Location'])
          .to match(/\/clusters\/#{cluster.shortcode}\/credit-usage$/)
        expect(flash[:success]).to eq '4 credits added to cluster Some Cluster.'

        cluster.reload
        expect(cluster.credit_balance).to eq 4

        post :deposit, params: params
        cluster.reload
        expect(cluster.credit_balance).to eq 8
      end

    end
  end
end
