require 'rails_helper'

RSpec.describe 'alces:cron:every_minute' do
  include_context 'rake'

  it_behaves_like 'it has prerequisite', 'alces:maintenance_windows:progress'
end
