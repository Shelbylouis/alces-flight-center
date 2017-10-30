require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let :site { create(:site) }
  let :user { create(:contact, site: site) }
  let! :first_cluster { create(:cluster, site: site, name: 'First cluster') }
  let! :second_cluster { create(:cluster, site: site, name: 'Second cluster') }
  let :first_cluster_component { create(:component, cluster: first_cluster) }

  before :each { sign_in_as(user) }

  describe 'GET #new' do
    context 'from top-level route' do
      it 'assigns all site clusters to @clusters' do
        get :new
        expect(assigns(:clusters)).to eq([first_cluster, second_cluster])
      end
    end

    context 'from cluster-level route' do
      it 'assigns just given cluster to @clusters' do
        get :new, params: { cluster_id: first_cluster.id }
        expect(assigns(:clusters)).to eq([first_cluster])
      end

      it 'gives 404 if cluster does not belong to user site' do
        another_cluster = create(:cluster)
        expect do
          get :new, params: { cluster_id: another_cluster.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context 'from component-level route' do
      it "assigns just given component's cluster to @clusters" do
        get :new, params: { component_id: first_cluster_component.id }
        expect(assigns(:clusters)).to eq([first_cluster])
      end

      it 'assigns given component to @single_component' do
        get :new, params: { component_id: first_cluster_component.id }
        expect(assigns(:single_component)).to eq(first_cluster_component)
      end

      it 'gives 404 if component does not belong to user site' do
        another_component = create(:component)
        expect do
          get :new, params: { component_id: another_component.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe 'POST #create' do
    let :valid_params do
      {
        case: {
          cluster_id: first_cluster.id,
          component_id: first_cluster_component.id,
          issue_id: create(:issue_requiring_component).id,
          details: 'Useful info'
        }
      }
    end

    context 'when JSON request' do
      let :response_json do
        JSON.parse(response.body).with_indifferent_access
      end

      it 'creates Case and returns success given valid params' do
        post :create, params: valid_params, format: :json

        expect(response).to have_http_status(:ok)
        expect(response_json).to match({errors: ''})
        expect(flash[:success]).to match(/successfully created/)

        matching_cases = Case.where(user: user)
        expect(matching_cases.length).to eq 1
        expect(matching_cases.first.details).to eq('Useful info')
      end

      it 'returns error status code and errors given invalid params' do
        invalid_params = valid_params.tap do |params|
          params[:case][:component_id] = nil
        end
        post :create, params: invalid_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json).to match(errors: /component/)
      end
    end
  end
end
