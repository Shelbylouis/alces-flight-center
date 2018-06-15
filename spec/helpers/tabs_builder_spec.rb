require 'rails_helper'

RSpec.describe TabsBuilder do
  before :each do
    allow(helper).to receive(:current_user).and_return(user)
  end
  let(:tab_builder) { TabsBuilder.new(user: user, scope: scope) }

  describe '#cases' do
    subject { tab_builder.cases[:dropdown].map { |h| h[:path] } }

    context 'when within the site scope' do
      let(:scope) { build_stubbed(:site) }

      context 'with an admin user' do
        let(:user) { build_stubbed(:admin) }

        it 'contains a link to the site cases' do
          expect(subject).to include(site_cases_path(scope))
        end

        it 'includes a link to the new case page for the site' do
          expect(subject).to include(new_site_case_path(scope))
        end
      end

      context 'with a contact user' do
        let(:user) { build_stubbed(:contact) }

        it 'contains a link to the cases page' do
          expect(subject).to include(cases_path)
        end

        it 'includes a link to the new case page' do
          expect(subject).to include(new_case_path)
        end
      end

      context 'with a viewer user' do
        let(:user) { build_stubbed(:viewer) }

        it 'does not include a link to the new case page' do
          expect(subject).not_to include(new_case_path)
        end
      end
    end
  end
end

