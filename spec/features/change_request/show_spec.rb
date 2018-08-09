require 'rails_helper'

RSpec.describe 'Change request view', type: :feature do

  EXPECTED_BUTTONS = {
    draft: {
      admin: ['Edit', 'Submit for authorisation', 'Cancel'],
      contact: [],
      viewer: [],
    },
    awaiting_authorisation: {
      admin: [],
      contact: ['Authorise', 'Request changes', 'Decline'],
      viewer: [],
    },
    declined: {
      admin: [],
      contact: [],
      viewer: [],
    },
    in_progress: {
      admin: ['Begin handover'],
      contact: [],
      viewer: [],
    },
    in_handover: {
      admin: [],
      contact: ['Approve work and close CR'],
      viewer: [],
    },
    completed: {
      admin: [],
      contact: [],
      viewer: [],
    },
    cancelled: {
      admin: [],
      contact: [],
      viewer: [],
    }
  }.freeze

  let(:site) { create(:site) }
  let(:admin) { create(:admin) }
  let(:contact) { create(:contact, site: site) }
  let(:viewer) { create(:viewer, site: site) }
  let(:cluster) { create(:cluster, site: site) }
  let(:kase) { build(:open_case, tier_level: 4, cluster: cluster) }


  EXPECTED_BUTTONS.keys.each do |state|
    context "for #{state} CR" do

      before(:each) do
        create(:change_request, state: state, case: kase)
      end

      EXPECTED_BUTTONS[state].keys.each do |user_type|

        it "shows #{user_type} expected buttons" do
          visit cluster_case_change_request_path(
            cluster, kase,
            as: send(user_type)
          )

          buttons = find('.state-controls').find_all('a.btn').map(&:text)
          expect(buttons).to eq( EXPECTED_BUTTONS[state][user_type] << 'Return to case' )
        end

      end

    end
  end

  it 'has test coverage for all possible CR states' do
    states = ChangeRequest.state_machine.states.keys

    expect(states.sort).to eq EXPECTED_BUTTONS.keys.sort
  end

  def as(whom)
    visit cluster_case_change_request_path(
              cluster, kase,
              as: whom
          )
    yield
  end

  it 'transitions a CR through states successfully' do

    cr = create(:change_request, state: :draft, case: kase)

    as(admin) { click_link('Submit for authorisation') }
    cr.reload
    expect(cr.state).to eq 'awaiting_authorisation'
    expect(find('.alert').text).to have_text("Change request #{kase.display_id} has been submitted for customer authorisation.")


    as(contact) { click_link('Authorise') }
    cr.reload
    expect(cr.state).to eq 'in_progress'
    expect(find('.alert').text).to have_text("Change request #{kase.display_id} authorised.")


    as(admin) { click_link('Begin handover') }
    cr.reload
    expect(cr.state).to eq 'in_handover'
    expect(find('.alert').text).to have_text("Change request #{kase.display_id} handed over for customer approval.")


    as(contact) { click_link('Approve work and close CR') }
    cr.reload
    expect(cr.state).to eq 'completed'
    expect(find('.alert').text).to have_text("Change request #{kase.display_id} completed.")
  end

  it 'transitions to :declined as a final state' do
    cr = create(:change_request, state: :awaiting_authorisation, case: kase)

    as(contact) { click_link('Decline') }
    cr.reload
    expect(cr.state).to eq 'declined'
    expect(find('.alert').text).to have_text("Change request #{kase.display_id} declined.")
  end

  it 'transitions to :cancelled as a final state' do
    cr = create(:change_request, state: :draft, case: kase)

    as(admin) { click_link('Cancel') }
    cr.reload
    expect(cr.state).to eq 'cancelled'
    expect(find('.alert').text).to have_text('Change request cancelled.')
  end

  it 'transitions back to draft upon requesting changes' do
    cr = create(:change_request, state: :awaiting_authorisation, case: kase)

    as(contact) { click_link('Request changes') }
    cr.reload
    expect(cr.state).to eq 'draft'
    expect(find('.alert').text).to have_text(
      "Change request #{kase.display_id} has been sent back for adjustments."
    )
  end

end
