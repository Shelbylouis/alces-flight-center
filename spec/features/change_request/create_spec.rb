require 'rails_helper'

RSpec.describe 'Change requests #create', type: :feature do

  let(:cluster) { create(:cluster) }
  let(:kase) { create(:open_case, cluster: cluster, tier_level: 3) }
  let(:admin) { create(:admin) }

  it 'creates a valid CR and moves the case to tier 4' do
    visit new_cluster_case_change_request_path(cluster, kase, as: admin)

    fill_in 'change_request_description', with: 'Description of change request'
    fill_in 'change_request_credit_charge', with: '42'

    click_button 'Create'

    expect(find('.alert-success').text).to have_text "Created change request for case #{kase.display_id}"

    kase.reload

    expect(kase.tier_level).to eq 4
    expect(kase.change_request.present?).to eq true
    expect(kase.change_request.description).to eq 'Description of change request'
    expect(kase.cr_in_progress?).to eq true
  end

  it 'ensures the created CR has a description' do
    visit new_cluster_case_change_request_path(cluster, kase, as: admin)

    fill_in 'change_request_description', with: ''
    fill_in 'change_request_credit_charge', with: '42'

    click_button 'Create'

    expect(find('.alert-danger').text).to have_text 'Error creating change request: description can\'t be blank'

    kase.reload

    expect(kase.tier_level).to eq 3
    expect(kase.change_request.present?).to eq false
  end

  it 'ensures the created CR has a charge' do
    visit new_cluster_case_change_request_path(cluster, kase, as: admin)

    fill_in 'change_request_description', with: 'Description of change request'
    fill_in 'change_request_credit_charge', with: ''

    click_button 'Create'

    expect(find('.alert-danger').text).to have_text 'Error creating change request: credit_charge can\'t be blank'

    kase.reload

    expect(kase.tier_level).to eq 3
    expect(kase.change_request.present?).to eq false
  end

end
