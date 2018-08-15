require 'rails_helper'

RSpec.describe DailyAdminReminder do
  let(:emails) { ActionMailer::Base.deliveries }

  let!(:admin_alpha) { create(:admin, name: 'Alpha One', email: 'alpha@example.com') }
  let!(:admin_beta) { create(:admin, name: 'Beta Two', email: 'beta@example.com') }
  let!(:admin_gamma) { create(:admin, name: 'Gamma Three', email: 'gamma@example.com') }

  let!(:case_a) { create(:open_case, assignee: admin_alpha, last_update: 2.hours.ago) }
  let!(:case_b) { create(:open_case, assignee: admin_alpha, last_update: 2.days.ago) }

  let!(:case_c) { create(:open_case, assignee: admin_beta, last_update: 4.hours.ago) }
  let!(:case_d) { create(:resolved_case, assignee: admin_beta) }

  let!(:case_e) { create(:resolved_case, assignee: admin_gamma) }
  let!(:case_f) { create(:closed_case, assignee: admin_gamma) }

  before(:each) do
    emails.clear
    DailyAdminReminder.process
  end


  it 'ignores admins with no assigned open cases' do
    expect(emails.count).to eq 2
    expect(emails.map(&:to).flatten).to eq [admin_alpha.email, admin_beta.email]
  end

  it 'includes only open cases in email' do
    expect(emails[1].parts.first.body.raw_source)
      .to include(case_c.display_id)
    expect(emails[1].parts.first.body.raw_source)
      .not_to include(case_d.display_id)
  end

  it 'lists cases in priority order' do
    expect(emails[0].parts.first.body.raw_source.delete("\n"))
      .to match(/#{case_b.display_id}.*#{case_a.display_id}/)
  end
end
