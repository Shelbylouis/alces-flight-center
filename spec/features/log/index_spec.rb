require 'rails_helper'

RSpec.feature Log, type: :feature do
  let(:engineer) { create(:admin) }
  let(:cluster) { create(:cluster) }

  # The following are ids for the view elements NOT the models
  let(:case_select_id) { 'log_case_ids' }
  let(:details_input_id) { 'log_details' }
  let(:component_select_id) { 'log_component_id' }

  # Create the components and cases for each spec
  before :each do
    create(:case, subject: 'Random other case')
    ['subject1', 'subject2', 'subject3'].each do |case_subject|
      create(:case, cluster: cluster, subject: case_subject)
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
      options = select_details_for subject.cases
      expect(page).to have_select case_select_id, options: options
    end

    it 'adds a log by the currently logged in engineer' do
      log_details = fill_details_input
      log = submit_log

      expect(log).not_to be_nil
      expect(log.details).to eq(log_details)
      expect(log.engineer).to eq(engineer)
      expect(log.cases).to be_blank
    end

    it 'can associate multiple cases with a log' do
      fill_details_input
      log_cases = [subject.cases.first, subject.cases.last].each do |kase|
        select kase.decorate.case_select_details, from: case_select_id
      end

      expect(submit_log.cases).to contain_exactly(*log_cases)
    end

    %w(resolved closed).each do |state|
      it "cannot select #{state} Case for subject to associate" do
        case_attributes = {
            cluster: cluster,
            subject: 'my_case'
        }
        if subject.is_a?(Component)
          case_attributes.merge!(
              component: subject,
              issue: create(:issue, requires_component: true)
          )
        end
        my_case = create("#{state}_case".to_sym, case_attributes)

        # Revisit the page so given Case would be shown, if we do not
        # successfully filter it out, to avoid false positive.
        visit current_path

        expect do
          select my_case.subject
        end.to raise_error(Capybara::ElementNotFound)
      end
    end

    it 'sends a notification to slack' do
      submit_log do |log|
        expect(SlackNotifier).to receive(:log_notification).with(log)
      end
    end
  end

  context 'when visiting the cluster log' do
    subject { cluster }
    before :each do
      visit cluster_logs_path subject, as: engineer
    end

    include_examples 'shared log features'

    it 'has the select component input with a blank option' do
      options = [""].concat subject.components.map(&:name)
      expect(page).to have_select component_select_id, options: options
    end

    it 'can create a log without a component' do
      fill_details_input
      expect(submit_log.component).to be_nil
      expect(page).to have_text 'None'
    end

    it 'can create a log with a component' do
      fill_details_input
      component = subject.components.last
      select component.name, from: component_select_id
      expect(submit_log.component).to eq(component)
      expect(page).to have_link(component.name, href: component_path(component))
    end
  end

  context 'when visiting the component log' do
    subject { cluster.components.first }

    before :each do
      ['component_case1', 'component_case2'].each do |case_subject|
        create :case_requiring_component,
               component: subject,
               subject: case_subject
      end
      visit component_logs_path subject, as: engineer
    end

    include_examples 'shared log features'

    it 'does not have the select component input' do
      expect(page).not_to have_select component_select_id
    end

    it 'creates a log for the current component' do
      fill_details_input
      expect(submit_log.component).to eq(subject)
    end
  end
end

