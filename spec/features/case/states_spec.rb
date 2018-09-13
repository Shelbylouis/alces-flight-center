require 'rails_helper'

RSpec.describe 'Case states', type: :feature do
  let(:contact) { create(:contact, site: site) }
  let(:admin) { create(:admin) }
  let(:site) { create(:site, name: 'My Site') }
  let(:cluster) { create(:cluster, site: site) }
  let(:time_worked) { 42 }

  let :open_case do
    create(
      :open_case,
      cluster: cluster,
      subject: 'Open case',
      tier_level: 2,
      time_worked: time_worked
    )
  end

  let :resolved_case do
    create(:resolved_case, cluster: cluster, subject: 'Resolved case', tier_level: 2)
  end

  let :closed_case do
    create(:closed_case, cluster: cluster, subject: 'Closed case', completed_at: 2.days.ago, tier_level: 2)
  end

  describe 'state controls' do
    it 'hides state controls for contacts' do
      visit cluster_case_path(cluster,open_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

      visit cluster_case_path(cluster,resolved_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)

      visit cluster_case_path(cluster,closed_case, as: contact)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'shows or hides state controls for admins' do
      visit cluster_case_path(cluster, open_case, as: admin)
      expect(find('#case-state-controls').find('a').text).to eq 'Resolve this case'

      visit cluster_case_path(cluster,resolved_case, as: admin)
      expect do
        find('#case-state-controls').find_button('Set charge and close case')
      end.not_to raise_error

      visit cluster_case_path(cluster,closed_case, as: admin)
      expect { find('#case-state-controls').find('a') }.to raise_error(Capybara::ElementNotFound)
    end

    it 'requires a charge to be specified to close a case' do
      visit cluster_case_path(cluster,resolved_case, as: admin)
      fill_in 'credit_charge_amount', with: ''
      click_button 'Set charge and close case'

      resolved_case.reload
      expect(resolved_case.state).to eq 'resolved'
      expect(find('.alert')).to have_text 'Error updating support case: credit_charge is invalid'
    end

    let(:cr_case) {
      create(:resolved_case, tier_level: 4, change_request: cr, cluster: cluster)
    }

    context 'with a declined change request' do
      let(:cr) {
        build(
          :change_request,
          credit_charge: 42,
          state: 'declined'
        )
      }

      it 'does not use CR charge as a minimum' do
        visit cluster_case_path(cluster, cr_case, as: admin)

        expect(find('#credit_charge_amount').value).to eq "0"
      end
    end

    context 'with a completed change request' do
      let!(:cr) {
        build(
          :change_request,
          credit_charge: 42,
          state: 'completed'
        )
      }

      it 'uses CR charge as a minimum' do
        visit cluster_case_path(cluster,cr_case, as: admin)

        expect(find('#credit_charge_amount').value).to eq "42"
        expect(find('#case-state-controls')).to have_text 'Charge below should include 42 credits from attached CR'
      end
    end

    (MaintenanceWindow.possible_states - MaintenanceWindow.finished_states)
      .map(&:to_s).each do |state|
      context "with a #{state} maintenance window" do
        let!(:mw) {
          create(
            :maintenance_window,
            case: open_case,
            state: state,
            clusters: [open_case.cluster]
          )
        }

        before(:each) do
          visit cluster_case_path(open_case.cluster, open_case, as: admin)
        end

        it 'does not allow case to be resolved' do
          state_controls = find('#case-state-controls')
          expect(state_controls).to have_text 'outstanding maintenance window.'
          expect(state_controls).not_to have_text 'Resolve this case'
        end

        it 'shows maintenance details' do
          details = find('#maintenance-details')
          expect(details).to have_text("(#{state == 'started' ? 'in progress' : state})")
        end
      end
    end

    MaintenanceWindow.finished_states.map(&:to_s).each do |state|
      context "with a #{state} maintenance window" do
        let!(:mw) {
          create(
            :maintenance_window,
            case: open_case,
            state: state,
            clusters: [open_case.cluster]
          )
        }

        before(:each) do
          visit cluster_case_path(open_case.cluster, open_case, as: admin)
        end

        it 'allows case to be resolved' do
          visit cluster_case_path(open_case.cluster, open_case, as: admin)

          state_controls = find('#case-state-controls')
          expect(state_controls).not_to have_text 'outstanding maintenance window.'
          expect(state_controls.find('a')).to have_text 'Resolve this case'
        end

        it 'does not show maintenance details' do
          expect do
            find('#maintenance-details')
          end.to raise_error Capybara::ElementNotFound
        end
      end
    end

    context 'without time added' do
      let(:time_worked) { nil }

      it 'does not allow case to be resolved' do
        visit cluster_case_path(open_case.cluster, open_case, as: admin)
        state_controls = find('#case-state-controls')
        expect(state_controls).to have_text 'until time worked is added.'
        expect(state_controls).not_to have_text 'Resolve this case'
      end
    end
  end

  describe 'case reopening' do

    let(:button_text) { 'Reopen this case' }

    before(:each) do
      visit cluster_case_path(cluster, resolved_case, as: user)
    end

    context 'for viewers' do
      let(:user) { create(:viewer, site: site) }
      it 'does not show reopen button' do
        expect do
          find_button button_text
        end.to raise_error Capybara::ElementNotFound
      end
    end

    RSpec.shared_examples 'reopening allowed' do
      it 'allows reopening a case with a comment' do
        click_button button_text

        fill_in 'comment', with: 'Reopen ALL the things!'
        click_button 'Reopen'

        resolved_case.reload
        expect(resolved_case).to be_open
        expect(resolved_case.tier_level).to be 3
        expect(find('.alert-success')).to have_text("Support case #{resolved_case.display_id} reopened.")
        expect(resolved_case.case_comments.last.text).to have_text 'Reopen ALL the things!'
        expect(resolved_case.case_comments.last.user).to eq user
      end
      it 'requires a comment to reopen a case' do
        click_button button_text

        click_button 'Reopen' # without adding a comment

        resolved_case.reload
        expect(resolved_case).to be_resolved
        expect(resolved_case.tier_level).to be 2
        expect(find('.alert-danger')).to have_text('You must provide a comment to reopen this case.')
      end
    end

    context 'for admins' do
      let(:user) { admin }
      include_examples 'reopening allowed'
    end

    context 'for contacts' do
      let(:user) { contact }
      include_examples 'reopening allowed'
    end
  end

end
