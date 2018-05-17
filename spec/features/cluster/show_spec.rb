require 'rails_helper'

RSpec.describe 'Cluster overview page', type: :feature do
  let :site { create(:site) }
  let :user { create(:contact, site: site) }
  let :cluster { create(:cluster, support_type: 'managed', site: site) }
  let :path { cluster_path(cluster, as: user) }

  [:component, :service].each do |part_type|
    before :each do
      4.times { create(part_type, cluster: cluster, support_type: 'inherit') }
      create(part_type, cluster: cluster, support_type: 'advice')
      create(part_type, cluster: cluster, support_type: 'managed')
    end

    it "has the correct text for #{part_type}s" do
      visit path

      list = all('li').map(&:text)
      expect(list).to have_text("5 fully managed #{part_type.to_s.pluralize}")
      expect(list).to have_text("1 self-managed #{part_type.to_s}")
    end
  end
end
