require 'rails_helper'

RSpec.describe 'Assigned cases table', type: :feature do
  let!(:admin) { create(:admin) }
  let(:path) { root_path(as: admin) }
  let(:cluster) { create(:cluster, site: site) }
  let(:site) { create(:site, name: 'Mr Site') }
  let!(:open_cases) {
    3.times {
      create(
        :open_case,
        cluster: cluster,
        assignee: admin,
        last_update: 1.hour.ago)
    }
  }
  let!(:last_updated) {
    create(
      :open_case,
      subject: 'Please update me',
      assignee: admin,
      last_update: 2.days.ago)
  }
  let!(:resolved_case) { create(:resolved_case, assignee: admin, last_update: 1.day.ago) }
  let!(:closed_case) { create(:closed_case, assignee: admin, last_update: Date.today) }

  context 'as an admin' do
    it 'has all assigned open cases' do
      visit(path)

      # Expect the value to be equal to the number of assigned open cases + 1.
      # This extra row exists because of the table column names
      expect(page.all('tr').count).to eq(5)
    end

    it 'has the least recently updated case at the top' do
      visit(path)
      expect(page.all('tr')[1].text.include? 'Please update me').to be true
    end
  end
end
