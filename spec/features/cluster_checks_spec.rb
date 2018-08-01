require 'rails_helper'

RSpec.describe 'Cluster checks', type: :feature do
  let(:site) { create(:site) }
  let(:contact) { create(:contact, site: site) }
  let(:admin) { create(:admin) }
  let(:cluster) { create(:cluster, site: site) }
  let(:check) { create(:check, name: 'Is everything on fire?') }
  let!(:cluster_check) { create(:cluster_check, check: check, cluster: cluster ) }
  let!(:check_result) {
    create(
      :check_result,
      cluster_check: cluster_check,
      date: Date.yesterday,
      user: admin
    )
  }

  describe 'Cluster submission form' do
    context 'as an admin' do
      let(:path) { cluster_check_submission_path(cluster, as: admin) }
      let!(:component) { create(:component, cluster: cluster) }

      before(:each) {
        visit path
      }

      it 'is accessible' do
        expect(page.status_code).to eq(200)
      end

      it 'contains the clusters check' do
        expect(page).to have_content('Is everything on fire?')
      end

      it 'submits results correctly' do
        choose 'success'
        click_button 'Submit Cluster Check Results'
        expect(cluster.check_results).to_not be_empty
      end

      it 'lets the user submit a comment' do
        fill_in("#{cluster_check.id}-comment", with: 'test comment')
        choose 'success'
        click_button 'Submit Cluster Check Results'
        expect(page).to have_content('test comment')
      end

      it 'creates a log if a component is selected' do
        fill_in("#{cluster_check.id}-comment", with: 'test log')
        select("#{component.name}", from: "#{cluster_check.id}-component")
        choose 'failure'
        click_button 'Submit Cluster Check Results'
        expect(cluster.logs).to_not be_empty
      end
    end

    context 'as a contact' do
      let(:path) { cluster_check_submission_path(cluster, as: contact) }

      it 'is not accessible' do
        visit path
        expect(page.status_code).to eq(403)
      end
    end

    context 'for a cluster with no checks' do
      let(:new_cluster) { create(:cluster) }
      let(:path) { cluster_check_submission_path(new_cluster, as: admin) }

      it 'displays correct message' do
        visit path
        expect(page).to have_content('There are no checks for this cluster currently')
      end
    end
  end

  describe 'Cluster check results page' do
    let(:path) { cluster_checks_path(cluster, as: contact) }

    before(:each) do
      visit path
    end

    context 'as an admin' do
      let(:path) { cluster_checks_path(cluster, as: admin) }

      it 'displays a button to set check results for today' do
        visit path
        expect(page).to have_content('Set check results for today')
      end
    end

    context 'as a contact' do
      let(:path) { cluster_checks_path(cluster, as: contact) }

      it 'does not display a button if there are no results for today' do
        expect(page).not_to have_content('Set check results for today')
      end

      it 'redirects to page with results for the entered date' do
        new_results = create(
          :check_result,
          cluster_check: cluster_check,
          date: Date.today,
          user: admin,
          comment: 'Nothing to see here'
        )
        visit cluster_checks_path(cluster, Date.yesterday, as: contact)
        expect(page).to have_content(Date.yesterday.to_formatted_s(:long))
        expect(page).to have_content(check_result.comment)
        expect(page).not_to have_content(new_results.comment)
      end
    end
  end
end
