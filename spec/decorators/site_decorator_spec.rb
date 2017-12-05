require 'rails_helper'

RSpec.describe SiteDecorator do
  describe '#case_form_buttons' do
    before :each do
      allow(h).to receive(:current_user).and_return(user)
    end

    subject { create(:site, users: [contact]).decorate }
    let :user { create(:user) }
    let :contact { create(:contact) }

    it 'gives nothing when Site has no managed Clusters' do
      expect(subject.case_form_buttons).to be nil
    end

    context 'when Site has managed Clusters' do
      before :each do
        create(:managed_cluster, site: subject)
      end

      context 'when contact' do
        let :user { contact }

        it 'includes link to top level Case form' do
          expect(subject.case_form_buttons).to include(
            h.new_case_path
          )
        end
      end

      context 'when admin' do
        let :user { create(:admin) }

        it 'includes link to Site Case form' do
          expect(subject.case_form_buttons).to include(
            h.new_site_case_path(subject)
          )
        end
      end
    end
  end
end
