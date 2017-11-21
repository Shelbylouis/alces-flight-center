require 'rails_helper'

RSpec.feature "Maintenance windows", type: :feature do
  context 'when user is an admin' do
    let :user { create(:admin) }

    let :start_link_path do
      start_maintenance_window_case_path(support_case.id)
    end
    let :end_link_path do
      end_maintenance_window_case_path(support_case.id)
    end

    context 'when Case has no Component' do
      let :support_case { create(:case) }

      it 'does not show start/end maintenance links' do
        visit site_cases_path(support_case.site, as: user)

        expect(page).not_to have_link(href: start_link_path)
        expect(page).not_to have_link(href: end_link_path)
      end
    end

    context 'when Case has Component' do
      let :support_case { create(:case_with_component) }

      it 'can switch a Case to/from under maintenance' do
        visit site_cases_path(support_case.site, as: user)

        start_link = page.find_link(href: start_link_path)
        expect(start_link).to have_css('.fa-wrench.interactive-icon')
        start_link.click
        expect(support_case).to be_under_maintenance
        expect(page).not_to have_link(href: start_link_path)

        end_link = page.find_link(href: end_link_path)
        expect(end_link).to have_css('.fa-heartbeat.interactive-icon')
        end_link.click
        expect(support_case).not_to be_under_maintenance
        expect(page).not_to have_link(href: end_link_path)
      end
    end
  end
end
