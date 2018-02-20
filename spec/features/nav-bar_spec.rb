
require 'rails_helper'

RSpec.feature Log, type: :feature do
  shared_examples 'has navigation link' do |link, position|
  end

  context 'with a user logged in' do
    def vist_as_user(path)
      visit path, as: create(:user)
    end

    context 'when visiting the site page' do
      subject { create(:site) }
      before :each { vist_as_user site_path(subject) }
      include_examples 'has navigation link', site_path(subject), 0
    end
  end
end

