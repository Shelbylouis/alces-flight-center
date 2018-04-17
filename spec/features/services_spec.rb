require 'rails_helper'

RSpec.feature '/services/', type: :feature do
  it_behaves_like 'can request support_type change via buttons', :service
end
