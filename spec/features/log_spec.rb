require 'rails_helper'

RSpec.feature 'Add Log', type: :feature do
  let :engineer { create(:admin) }
  let :cluster { create(:cluster) }

  # The following are ids for the view elements NOT the models
  let :case_select_id { 'log_case_ids' }
  let :details_input_id { 'log_details' }
  let :component_select_id { 'log_component_id' }

  # Create the components and cases for each spec
  before :each do
    create(:case, details: 'Random other case')
    ['details1', 'details2', 'details3'].each do |details|
      create(:case, cluster: cluster, details: details)
    end

    create(:component, name: 'Random other component')
    ['component1', 'component2', 'component3'].each do |name|
      create(:component, cluster: cluster, name: name)
    end
  end

  # NOTE: This method is currently kinda flaky. It only returns the correct
  # log if it is created successfully and there is only one log. Consider
  # making it more robust at some point.
  def submit_log
    click_button 'Submit'
    Log.first
  end

  def fill_details_input
    'I am the details for the log'.tap do |details|
      fill_in details_input_id, with: details
    end
  end

  def select_details_for(input_cases)
    input_cases.map(&:decorate).map(&:case_select_details)
  end

  shared_examples 'shared log features' do
    it 'has the case select box' do
      expect(page).to have_select case_select_id,
                                  options: select_details_for(cluster.cases)
    end

    it 'adds a log by the currently logged in engineer' do
      log_details = fill_details_input
      log = submit_log

      expect(log).not_to be_nil
      expect(log.details).to eq(log_details)
      expect(log.engineer).to eq(engineer)
      expect(log.cases).to be_blank
    end

    it 'can add multiple tickets/cases to the view' do
      fill_details_input
      log_cases = [cluster.cases.first, cluster.cases.last].each do |kase|
        select kase.decorate.case_select_details, from: case_select_id
      end

      expect(submit_log.cases).to contain_exactly(*log_cases)
    end
  end

  context 'when visiting the cluster log' do
    before :each do
      visit cluster_logs_path cluster, as: engineer
    end

    include_examples 'shared log features'

    it 'has the select component input' do
      expect(page).to have_select component_select_id,
                                  options: cluster.components.map(&:name)
    end
  end
end

