require 'rails_helper'

RSpec.feature 'Asset Record', type: :feature   do
  let :admin { create(:admin) }
  let :component { create(:component) }
  let :component_group { create(:component_group) }

  context 'with an invalid request' do
    it 'errors as a non-admin user' do
      expect do
        visit edit_component_asset_record_path(component)
      end.to raise_error(ActionController::RoutingError)
    end

    it 'errors if component_group is sent with a component request' do
      expect do
        visit edit_component_asset_record_path(
          component, as: admin, component_group_id: component_group
        )
      end.to raise_error(RuntimeError)
    end
  end

  context 'with a component' do
    subject { component }
    let :edit_path do
      edit_component_asset_record_path(subject, as: admin)
    end

    it 'redirect to the component' do
      visit edit_path
      click_button('Submit')
      expect(current_path).to eq(component_path subject)
    end
  end

  context 'with a component group' do
    subject { component_group }
    let :edit_path do
      edit_component_group_asset_record_path(subject, as: admin)
    end

    it 'redirects to the component_group' do
      visit edit_path
      click_button 'Submit'
      expect(current_path).to eq(component_group_path subject)
    end
  end
end
