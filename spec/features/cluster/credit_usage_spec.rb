require 'rails_helper'

RSpec.describe 'Cluster credit usage', type: :feature do
  let(:site) { create(:site) }
  let(:admin) { create(:admin) }
  let(:user) { create(:contact, site: site) }
  let(:cluster) { create(:cluster, support_type: 'managed', site: site) }

  it 'shows credit events for the current period' do
    c1 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 1))
    c2 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 2))
    c3 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 4))

    cluster.credit_deposits.create(amount: 10, user: admin)

    visit cluster_credit_usage_path(cluster, as: user)

    events = find_all('li.credit-charge-entry')

    expect(events.length).to eq 4

    expect(events[3].text).to match(/#{c1.display_id}.*-1 credits$/)
    expect(events[2].text).to match(/#{c2.display_id}.*-2 credits$/)
    expect(events[1].text).to match(/#{c3.display_id}.*-4 credits$/)
    expect(events[0].text).to match(/Credits added.* 10 credits$/)

    expect(find('.credit-balance').text).to eq '3 credits'
  end

  it 'shows a friendly message with no credit events' do
    visit cluster_credit_usage_path(cluster, as: user)

    expect(find('.no-events-message').text).to eq 'No credit usage or accrual in this period.'
  end
end
