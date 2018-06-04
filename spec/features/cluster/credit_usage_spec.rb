require 'rails_helper'

RSpec.describe 'Cluster credit usage', type: :feature do
  let(:site) { create(:site) }
  let(:admin) { create(:admin) }
  let(:user) { create(:contact, site: site) }
  let(:cluster) { create(:cluster, support_type: 'managed', site: site) }

  it 'shows credit events for the current period' do
    c1 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 1))
    c2 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 0))
    c3 = create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 4))

    cluster.credit_deposits.create(amount: 10, user: admin)

    visit cluster_credit_usage_path(cluster, as: user)

    events = find_all('li.credit-charge-entry')

    expect(events.length).to eq 4

    expect(events[3].text).to match(/#{c1.display_id}.*-1 credits$/)
    expect(events[2].text).to match(/#{c2.display_id}.*0 credits$/)
    expect(events[1].text).to match(/#{c3.display_id}.*-4 credits$/)
    expect(events[0].text).to match(/Credits added.* 10 credits$/)

    expect(find('.credit-balance').text).to eq '5 credits'
  end

  it 'shows a friendly message with no credit events' do
    visit cluster_credit_usage_path(cluster, as: user)

    expect(find('.no-events-message').text).to eq 'No credit usage or accrual in this period.'
  end

  describe 'navigation through time' do
    include ActiveSupport::Testing::TimeHelpers

    before(:each) do
      travel_to Time.zone.local(2017, 9, 30) do
        # Create cluster (implicitly) and charge event in Q3 2017
        create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 1))
      end

      travel_to Time.zone.local(2017, 10, 1) do
        # Create a deposit and charge in Q4 2017
        create(:closed_case, cluster: cluster, credit_charge: build(:credit_charge, amount: 2))
        cluster.credit_deposits.create(amount: 4, user: admin)
      end
    end

    it 'lists all quarters from cluster creation to present' do
      travel_to Time.zone.local(2018, 6, 1) do
        visit cluster_credit_usage_path(cluster, as: user)

        expect(find('.credit-balance').text).to eq '1 credit'
        expect(find('.no-events-message').text).to eq 'No credit usage or accrual in this period.'

        form = find('#credit-quarter-selection')

        available_quarters = form.find_all('option').map(&:value)
        expect(available_quarters).to eq(%w(2018-04-01 2018-01-01 2017-10-01 2017-07-01))
      end
    end

    it 'lists events in selected quarters' do
      visit cluster_credit_usage_path(cluster, start_date: '2017-07-01', as: user)

      events = find_all('li.credit-charge-entry')

      expect(events.length).to eq 1
      expect(events[0].text).to match(/-1 credits$/)

      visit cluster_credit_usage_path(cluster, start_date: '2017-10-01', as: user)

      events = find_all('li.credit-charge-entry')

      expect(events.length).to eq 2
      expect(events[1].text).to match(/-2 credits$/)
      expect(events[0].text).to match(/Credits added.* 4 credits$/)

      visit cluster_credit_usage_path(cluster, start_date: '2018-01-01', as: user)

      events = find_all('li.credit-charge-entry')

      expect(events.length).to eq 0
    end
  end
end
