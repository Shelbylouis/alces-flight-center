require 'rails_helper'

RSpec.describe 'Navigation variable assignments', type: :request do
  let :contact { create(:contact, site: site) }
  let :admin { create(:admin) }
  let :site { create(:site) }
  let! :cluster { create(:cluster, site: site) }
  let! :component { create(:component, cluster: cluster) }
  let! :service { create(:service, cluster: cluster) }

  before :each do
    # Avoid making any S3 requests for Cluster documents.
    allow_any_instance_of(Cluster).to receive(:documents).and_return []
  end

  def assigns_navigation_variables(vars)
    vars.each do |var, value|
      expect(assigns(var)).to eq value
    end
  end

  context 'when no user' do
    describe "get '/'" do
      before :each do
        get root_path
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: nil,
          cluster: nil,
          cluster_part: nil
        )
      end
    end
  end

  context 'when user is site contact' do
    describe "get '/'" do
      before :each do
        get root_path(as: contact)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: nil,
          cluster_part: nil
        )
      end
    end

    describe "get '/cluster/*'" do
      before :each do
        get cluster_path(cluster.id, as: contact)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: nil
        )
      end

    end

    describe "get /components/*" do
      before :each do
        get component_path(component.id, as: contact)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: component
        )
      end
    end

    describe "get /services/*" do
      before :each do
        get service_path(service.id, as: contact)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: service
        )
      end
    end
  end

  context 'when user is admin' do
    describe "get '/'" do
      before :each do
        get root_path(as: admin)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: nil,
          cluster: nil,
          cluster_part: nil
        )
      end
    end

    describe "get '/sites/*'" do
      before :each do
        get site_path(site.id, as: admin)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: nil,
          cluster_part: nil
        )
      end
    end

    describe "get '/cluster/*'" do
      before :each do
        get cluster_path(cluster.id, as: admin)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: nil
        )
      end
    end

    describe "get /components/*" do
      before :each do
        get component_path(component.id, as: admin)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: component
        )
      end
    end

    describe "get /services/*" do
      before :each do
        get service_path(service.id, as: admin)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: service
        )
      end
    end
  end
end
