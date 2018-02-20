
require 'rails_helper'

RSpec.feature Log, type: :feature do
  let :nav_bar { find_by_id('top-level-navigation-bar') }

  shared_examples 'a navigation bar' do
    it 'has the navigation bar' do
      expect(nav_bar.tag_name).to eq('nav')
    end
  end

  context 'with an admin logged in' do
    def visit_as_admin(path_helper)
      visit send(path_helper, scope, as: create(:admin))
    end

    context 'when visiting the site page' do
      let :scope { create(:site) }
      before :each { visit_as_admin :site_path }

      include_examples 'a navigation bar'
    end
  end
end

