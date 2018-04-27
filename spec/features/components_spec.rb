require 'rails_helper'

RSpec.feature '/components/', type: :feature do
  it_behaves_like 'can request support_type change via buttons', :component
end
