require 'rails_helper'

RSpec.describe 'Change request view', type: :feature do

  EXPECTED_BUTTONS = {
    draft: {
      admin: ['Edit', 'Submit for authorisation'],
      contact: [],
    },
    awaiting_authorisation: {
      admin: [],
      contact: ['Authorise', 'Decline'],
    },
    declined: {
      admin: [],
      contact: [],
    },
    in_progress: {
      admin: ['Begin handover'],
      contact: [],
    },
    in_handover: {
      admin: [],
      contact: ['Approve work and close CR'],
    },
    completed: {
      admin: [],
      contact: [],
    }
  }.freeze

  let(:site) { create(:site) }
  let(:admin) { create(:admin) }
  let(:contact) { create(:contact, site: site) }
  let(:cluster) { create(:cluster, site: site) }
  let(:kase) { create(:open_case, tier_level: 4, cluster: cluster) }


  EXPECTED_BUTTONS.keys.each do |state|
    context "for #{state} CR" do

      subject { create(:change_request, state: state, case: kase) }

      EXPECTED_BUTTONS[state].keys.each do |user_type|

        it "shows #{user_type} expected buttons" do
          visit cluster_case_change_request_path(
            cluster, kase, subject,
            as: send(user_type)
          )

          buttons = find('.state-controls').find_all('a.btn').map(&:text)
          expect(buttons).to eq( EXPECTED_BUTTONS[state][user_type] << 'Return to case' )
        end

      end

    end
  end

  it 'has test coverage for all possible CR states' do
    cr = create(:change_request)
    states = cr.state_paths(from: :draft).flatten.map(&:to_name).uniq << :draft

    expect(states.sort).to eq EXPECTED_BUTTONS.keys.sort
  end

  def as(whom)
    visit cluster_case_change_request_path(
              cluster, kase, subject,
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

end
