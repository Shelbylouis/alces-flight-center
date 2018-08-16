require 'rails_helper'

RSpec.describe 'Show notes page', type: :feature do
  let(:site) { create(:site) }
  let(:cluster) { create(:cluster, site: site) }

  let(:path) { cluster_notes_path(cluster, :customer, as: user) }

  before :each do
    visit path
  end

  it 'needs tests updating for new multi-note world'
end
