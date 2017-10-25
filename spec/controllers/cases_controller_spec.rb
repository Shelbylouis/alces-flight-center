require 'rails_helper'

RSpec.describe CasesController, type: :controller do
  describe 'GET #new' do
    let :site { create(:site) }
    let :user { create(:contact, site: site) }
    let :first_cluster { create(:cluster, site: site, name: 'First cluster') }
    let :second_cluster { create(:cluster, site: site, name: 'Second cluster') }

    before :each { sign_in_as(user) }

    context 'from top-level route' do
      it 'assigns all site clusters to @clusters' do
        get :new
        expect(assigns(:clusters)).to eq([first_cluster, second_cluster])
      end
    end
  end
end
