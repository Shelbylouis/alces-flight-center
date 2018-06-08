require 'rails_helper'

RSpec.describe TabsBuilder do
  before :each do
    allow(helper).to receive(:current_user).and_return(user)
  end
  let(:tab_builder) { TabsBuilder.new(scope) }

  describe '#cases' do
    subject { tab_builder.cases[:dropdown].map { |h| h[:path] } }

    context 'when within the site scope' do
      let(:scope) { create(:site) }

      context 'with an admin user' do
        let(:user) { create(:admin) }

        it 'contains a link to the site cases' do
          expect(subject).to include(site_cases_path(scope))
        end
      end

      context 'with a contact user' do
        let(:user) { create(:contact) }

        it 'contains a link to the cases page' do
          expect(subject).to include(cases_path)
        end
      end
    end
  end
end

