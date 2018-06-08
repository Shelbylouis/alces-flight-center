require 'rails_helper'

RSpec.describe 'Site page', type: :feature do
  let(:site) { create(:site) }

  describe 'Create Cluster Case button' do
    let!(:cluster) { create(:cluster, site: site) }

    let(:create_button_text) { 'Create case' }

    context 'for viewer' do
      let(:viewer) do
        create(:viewer, site: site)
      end

      it 'has disabled create case button' do
        visit root_path(as: viewer)

        button = find('a', text: create_button_text)

        expect(button).to be_disabled
        expect(button[:class]).to include('disabled')
        expect(button[:title]).to eq(
          'As a viewer you cannot create a case'
        )
      end
    end

    context 'for non-viewer' do
      let(:contact) do
        create(:contact, site: site)
      end

      it 'does not have disabled create case button' do
        visit root_path(as: contact)

        button = find('a', text: create_button_text)

        expect(button).not_to be_disabled
        expect(button[:class]).not_to include('disabled')
        expect(button[:title]).to be nil
      end
    end
  end
end
