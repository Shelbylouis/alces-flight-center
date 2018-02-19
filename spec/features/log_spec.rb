require 'rails_helper'

RSpec.feature 'Add Log', type: :feature do
  let :engineer { create(:admin) }
  let :cluster { create(:cluster) }
  let :case_details { ['details1', 'details2', 'details3'] }
  let! :cases do
    create(:case, details: 'Random other case')
    case_details.map { |d| create(:case, cluster: cluster, details: d) }
  end
  let! :components do
    create(:component, name: 'Random other component')
    ['component1', 'component2', 'component3'].map do |name|
      create(:component, cluster: cluster, name: name)
    end
  end
  let :case_select_details do
    cases.map { |c| c.decorate.case_select_details }
  end
  let :case_select_id { 'log_case_ids' }
  let :case_details_id { 'log_details' }
  let :component_select_id { 'log_component_id' }

  def submit_log
    click_button 'Submit'
    Log.first
  end

  shared_examples 'shared log features' do
    it 'has the case select box' do
      expect(page).to have_select case_select_id,
                                  options: case_select_details
    end

    it 'adds a log by the currently logged in engineer' do
      log_details = 'New log details to make sure the match is correct'
      fill_in case_details_id, with: log_details
      log = submit_log

      expect(log).not_to be_nil
      expect(log.details).to eq(log_details)
      expect(log.engineer).to eq(engineer)
      expect(log.cases).to be_blank
    end

    it 'can add multiple tickets/cases to the view' do
      fill_in case_details_id, with: 'The details need to be filled'
      log_cases = [cases.first, cases.last].each do |kase|
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
                                  options: components.map(&:name)
    end
  end
end

