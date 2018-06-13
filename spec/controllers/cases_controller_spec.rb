require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  let(:site) { create(:site) }
  let(:user) { create(:contact, site: site) }
  let!(:first_cluster) { create(:cluster, site: site, name: 'First cluster') }
  let!(:second_cluster) { create(:cluster, site: site, name: 'Second cluster') }
  let(:first_cluster_component) { create(:component, cluster: first_cluster) }
  let!(:first_cluster_service) { create(:service, cluster: first_cluster) }

  before(:each) { sign_in_as(user) }

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

      context 'case form pre-population' do
        before(:each) do
          # Add additional tools and services so that we can be confident we
          # are selecting the correct items, and not just selecting the only
          # items that are in the database.
          create(:tier)
          create(:level_1_tier)
          create(:category)
          create(:service, service_type: create(:service_type), cluster: first_cluster)
        end

        let(:category) { create(:category, name: 'My category name') }
        let(:tier) { create(:tier_with_tool, issue: issue) }
        let(:service_type) { create(:service_type) }
        let!(:service) do
          create(:service, service_type: service_type, cluster: first_cluster, name: 'My service name')
        end
        let!(:issue) do
          create(:issue_requiring_service, service_type: service_type, category: category, name: 'My issue name')
        end


        context 'when given a tool' do
          it 'assigns the correct tool to @pre_selected' do
            get :new, params: { tool: tier.tool, cluster_id: first_cluster.id }

            expect(assigns(:pre_selected)).to eq({
              tool: tier.tool
            })
          end
        end

        context 'when given a service' do
          it 'assigns the correct service id to @pre_selected' do
            get :new, params: { service: service.name, cluster_id: first_cluster.id }

            expect(assigns(:pre_selected)).to eq({
              service: service.id,
            })
          end
        end

        context 'when given a category' do
          it 'assigns the correct category id to @pre_selected' do
            issue = category.issues.first
            service = issue.present? ?
              Service.find_by(service_type: issue.service_type, cluster: first_cluster) :
              nil

            get :new, params: { category: category.name, cluster_id: first_cluster.id }

            expect(assigns(:pre_selected)).to eq({
              category: category.id,
              service: service.present? ? service.id : nil,
            })
          end
        end

        context 'when given a issue' do
          it 'assigns the correct service, category, issue and tier to @pre_selected' do
            service = Service.find_by(service_type: issue.service_type, cluster: first_cluster)

            get :new, params: { issue: issue.name, cluster_id: first_cluster.id }

            expect(assigns(:pre_selected)).to eq({
              category: issue.category.id,
              issue: issue.id,
              service: service.id,
              tier: issue.tiers.first.id,
            })
          end
        end

        context 'when given no pre-populations' do
          it 'does not assign anything to @pre_selected' do
            get :new, params: { cluster_id: first_cluster.id }

            expect(assigns(:pre_selected)).to eq({})
          end
        end
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
        expect(response_json).to match({redirect: /\/cases\/.+/})
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
      let(:expected_redirect_path) { cluster_path(first_cluster) }

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
      expect(flash[:success]).to eq "Support case #{open_case.display_id} resolved."
    end

    it 'closes a resolved case' do
      post :close, params: { id: resolved_case.id, credit_charge: { amount: 0 } }
      expect(flash[:success]).to eq "Support case #{resolved_case.display_id} closed."
    end

    it 'requires a credit charge to close a resolved case' do
      post :close, params: { id: resolved_case.id }
      expect(flash[:error]).to eq 'You must specify a credit charge to close this case.'
    end

    it 'does not resolve a closed case' do
      post :resolve, params: { id: closed_case.id }
      expect(flash[:error]).to eq 'Error updating support case: state cannot transition via "resolve"'
    end

    it 'does not close an open case' do
      post :close, params: { id: open_case.id, credit_charge: { amount: 0 } }
      expect(flash[:error]).to eq 'Error updating support case: state cannot transition via "close"'
    end
  end

  describe 'case time management' do

    let(:some_case) { create(:open_case, time_worked: 0)}
    let(:admin) { create(:admin) }

    before(:each) { sign_in_as(admin) }

    it 'converts from hours and minutes to minutes on a case' do
      post :set_time, params: { id: some_case.id, time: { hours: 3, minutes: 21 }}
      some_case.reload
      expect(some_case.time_worked).to eq (3 * 60) + 21
      expect(flash[:success]).to eq "Updated 'time worked' for support case #{some_case.display_id}."
    end
  end

  describe 'POST #escalate' do
    let (:open_case) {
      create(:open_case, cluster: first_cluster, tier_level: 2)
    }

    let (:resolved_case) {
      create(:resolved_case, cluster: first_cluster, tier_level: 2)
    }

    let (:closed_case) {
      create(:closed_case, cluster: first_cluster, tier_level: 2)
    }

    let(:admin) { create(:admin) }

    RSpec.shared_examples 'case escalation behaviour' do
      it 'escalates an open case' do
        post :escalate, params: { id: open_case.id }
        expect(flash[:success]).to eq "Support case #{open_case.display_id} escalated."

        open_case.reload

        expect(open_case.tier_level).to eq 3
      end

      %w(resolved closed).each do |state|
        it "does not escalate a #{state} case" do
          kase = send("#{state}_case")
          post :escalate, params: { id: kase.id }

          expect(flash[:error]).to eq "Error updating support case: tier_level cannot be changed when a case is #{state}"
          kase.reload
          expect(open_case.tier_level).to eq 2
        end
      end
    end

    context 'as an admin' do
      before(:each) { sign_in_as(admin) }
      it_behaves_like 'case escalation behaviour'
    end

    context 'as a contact' do
      before(:each) { sign_in_as(user) }
      it_behaves_like 'case escalation behaviour'
    end
  end
end
