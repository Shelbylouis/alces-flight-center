require 'rails_helper'

RSpec.describe 'Navigation variable assignments', type: :request do
  let :contact { create(:contact, site: site) }
  let :admin { create(:admin) }
  let :site { create(:site) }
  let! :cluster { create(:cluster, site: site) }
  let! :component_group { create(:component_group) }
  let! :component do
    create(:component, component_group: component_group, cluster: cluster)
  end
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

  RSpec.shared_examples 'cluster and part variable assignment' do
    describe "get '/cluster/*'" do
      before :each do
        get cluster_path(cluster.id, as: user)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: nil,
          component_group: nil
        )
      end
    end

    describe "get /components/*" do
      before :each do
        get component_path(component.id, as: user)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: component,
          component_group: component_group
        )
      end
    end

    describe "get /component_group/*" do
      before :each do
        get component_group_path(component_group.id, as: user)
      end

      it 'assigns the correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: nil,
          component_group: component_group
        )
      end
    end

    describe "get /services/*" do
      before :each do
        get service_path(service.id, as: user)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: cluster,
          cluster_part: service,
          component_group: nil
        )
      end
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
          cluster_part: nil,
          component_group: nil
        )
      end
    end
  end

  context 'when user is site contact' do
    let :user { contact }

    include_examples 'cluster and part variable assignment'

    describe "get '/'" do
      before :each do
        get root_path(as: user)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: nil,
          cluster_part: nil,
          component_group: nil
        )
      end
    end
  end

  context 'when user is admin' do
    let :user { admin }

    include_examples 'cluster and part variable assignment'

    describe "get '/'" do
      before :each do
        get root_path(as: user)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: nil,
          cluster: nil,
          cluster_part: nil,
          component_group: nil
        )
      end
    end

    describe "get '/sites/*'" do
      before :each do
        get site_path(site.id, as: user)
      end

      it 'assigns correct navigation variables' do
        assigns_navigation_variables(
          site: site,
          cluster: nil,
          cluster_part: nil,
          component_group: nil
        )
      end
    end
  end
end
