require 'rails_helper'

RSpec.describe 'Navigation variable assignments', type: :request do
  let :contact { create(:contact, site: site) }
  let :site { create(:site) }
  let! :cluster { create(:cluster, site: site) }
  let! :component { create(:component, cluster: cluster) }
  let! :service { create(:service, cluster: cluster) }

  before :each do
    # Avoid making any S3 requests for Cluster documents.
    allow_any_instance_of(Cluster).to receive(:documents).and_return []
  end

  RSpec.shared_examples 'assigns @site' do
    it 'assigns @site' do
      expect(assigns(:site)).to eq site
    end
  end

  RSpec.shared_examples 'assigns @cluster' do
    it 'assigns @cluster' do
      expect(assigns(:cluster)).to eq cluster
    end
  end

  RSpec.shared_examples 'does not assign @cluster_part' do
    it 'does not assign @cluster_part' do
      expect(assigns(:cluster_part)).to be nil
    end
  end

  context 'when no user' do
    describe "get '/'" do
      before :each do
        get root_path
      end

      it 'does not assign @site' do
        expect(assigns(:site)).to be nil
      end
    end
  end

  context 'when user is site contact' do
    describe "get '/'" do
      before :each do
        get root_path(as: contact)
      end

      include_examples 'assigns @site'
      include_examples 'does not assign @cluster_part'

      it 'does not assign @cluster' do
        expect(assigns(:cluster)).to be nil
      end
    end

    describe "get '/cluster/*'" do
      before :each do
        get cluster_path(cluster.id, as: contact)
      end

      include_examples 'assigns @site'
      include_examples 'assigns @cluster'
      include_examples 'does not assign @cluster_part'
    end

    describe "get /components/*" do
      before :each do
        get component_path(component.id, as: contact)
      end

      include_examples 'assigns @site'
      include_examples 'assigns @cluster'

      it 'assigns @cluster_part to Component' do
        expect(assigns(:cluster_part)).to eq component
      end
    end

    describe "get /services/*" do
      before :each do
        get service_path(service.id, as: contact)
      end

      include_examples 'assigns @site'
      include_examples 'assigns @cluster'

      it 'assigns @cluster_part to Service' do
        expect(assigns(:cluster_part)).to eq service
      end
    end
  end
end
