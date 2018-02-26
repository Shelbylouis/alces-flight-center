require 'rails_helper'

RSpec.describe 'alces:cron:every_minute' do
  include_context 'rake'

  it 'has alces:maintenance_windows:progress prerequisite' do
    expect(subject.prerequisites).to include('alces:maintenance_windows:progress')
  end
end
