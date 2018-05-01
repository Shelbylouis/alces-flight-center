require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let :site { create(:site) }
  let :user { create(:contact, site: site) }
  let! :first_cluster { create(:cluster, site: site, name: 'First cluster') }
  let! :second_cluster { create(:cluster, site: site, name: 'Second cluster') }
  let :first_cluster_component { create(:component, cluster: first_cluster) }
  let! :first_cluster_service { create(:service, cluster: first_cluster) }

  before :each { sign_in_as(user) }

  describe 'GET #new' do
    context 'from top-level route' do
      it 'assigns all site clusters to @clusters' do
        get :new
        expect(assigns(:clusters)).to match_array([first_cluster, second_cluster])
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

      it 'assigns given component to @single_part' do
        get :new, params: { component_id: first_cluster_component.id }
        expect(assigns(:single_part)).to eq(first_cluster_component)
      end

      it 'gives 404 if component does not belong to user site' do
        another_component = create(:component)
        expect do
          get :new, params: { component_id: another_component.id }
        end.to raise_error(ActionController::RoutingError)
      end
    end

    context 'from service-level route' do
      it "assigns just given service's cluster to @clusters" do
        get :new, params: { service_id: first_cluster_service.id }
        expect(assigns(:clusters)).to eq([first_cluster])
      end

      it 'assigns given service to @single_part' do
        get :new, params: { service_id: first_cluster_service.id }
        expect(assigns(:single_part)).to eq(first_cluster_service)
      end

      it 'gives 404 if service does not belong to user site' do
        another_service = create(:service)
        expect do
          get :new, params: { service_id: another_service.id }
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
          subject: 'some_subject',
          details: 'Useful info',
          tier_level: 2,
          fields: [{
            type: 'textarea',
            name: 'some_field',
            value: 'some_value',
          }],
        }
      }
    end

    let :params_without_required_component do
      valid_params.tap do |params|
        params[:case][:component_id] = nil
      end
    end

    def expect_case_created
      user_cases = Case.where(user: user)
      expect(user_cases.length).to eq 1
      expect(user_cases.first.subject).to eq('some_subject')
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
        expect_case_created
      end

      it 'returns error status code and errors given invalid params' do
        post :create, params: params_without_required_component, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response_json).to match(errors: /component/)
      end
    end

    context 'when HTML request' do
      let :expected_redirect_path { cluster_path(first_cluster) }

      it 'creates Case and redirects given valid params' do
        post :create, params: valid_params, format: :html

        expect(response).to redirect_to(expected_redirect_path)
        expect(flash[:success]).to match(/successfully created/)
        expect_case_created
      end

      it 'flashes errors and redirects given invalid params' do
        post :create, params: params_without_required_component, format: :html

        expect(response).to redirect_to(expected_redirect_path)
        expect(flash[:error]).to match(/Error creating support case: component/)
      end

      context 'when not given Cluster' do
        it 'redirects to root_path' do
          params = valid_params.tap do |p|
            p[:case].reject! do |k,v|
              # Delete Cluster and part (which might cause automatic
              # association with Cluster on Case creation).
              [:cluster_id, :component_id, :service_id].include?(k)
            end
          end
          post :create, params: params, format: :html

          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe 'case state management' do
    let (:open_case) {
      create(:open_case)
    }

    let (:resolved_case) {
      create(:resolved_case)
    }

    let (:closed_case) {
      create(:closed_case)
    }

    let(:admin) { create(:admin) }

    before(:each) { sign_in_as(admin) }

    it 'resolves an open case' do
      post :resolve, params: { id: open_case.id }
      expect(flash[:success]).to eq "Support case ##{open_case.id} resolved."
    end

    it 'closes a resolved case' do
      post :close, params: { id: resolved_case.id }
      expect(flash[:success]).to eq "Support case ##{resolved_case.id} closed."
    end

    it 'does not resolve a closed case' do
      post :resolve, params: { id: closed_case.id }
      expect(flash[:error]).to eq 'Error updating support case: state cannot transition via "resolve"'
    end

    it 'does not close an open case' do
      post :close, params: { id: open_case.id }
      expect(flash[:error]).to eq 'Error updating support case: state cannot transition via "close"'
    end
  end
end
