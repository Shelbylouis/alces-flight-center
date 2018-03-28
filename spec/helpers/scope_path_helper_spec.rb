require 'rails_helper'

RSpec.describe ScopePathHelper do
  before :each do
    allow(helper).to receive(:current_user).and_return(user)
  end

  context 'with a contact logged in' do
    let :user { create(:contact) }

    describe '#respond_to' do
      it 'responds to #scope_path' do
        expect(helper.respond_to? :scope_path).to eq(true)
      end

      it 'does not respond to #_scope_path' do
        expect(helper.respond_to? :_scope_path).to eq(false)
      end
    end

    describe '#scope_path' do
      subject { helper.scope_path(scope) }

      context 'when in a cluster scope' do
        let :scope { create(:cluster) }

        it 'finds the path' do
          expect(subject).to eq(helper.cluster_path(scope))
        end
      end
    end
  end

  context 'with an admin logged in' do
    let :user { create(:admin) }

    describe '#scope_path' do
      subject { helper.scope_path(scope) }

      context 'when in a site scope' do
        let :scope { create(:site) }

        it 'returns the site path' do
          expect(subject).to eq(site_path(scope))
        end
      end
    end
  end
end

