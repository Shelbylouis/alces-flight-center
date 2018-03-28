require 'rails_helper'

RSpec.describe 'scope_path decorator methods' do
  context 'in a cluster scope' do
    let :scope { create(:cluster).decorate }

    describe '#respond_to' do
      it 'responds to #scope_path' do
        expect(scope.respond_to? :scope_path).to eq(true)
      end

      it 'does not respond to #_scope_path' do
        expect(scope.respond_to? :_scope_path).to eq(false)
      end
    end
  end

  describe '#scope_cases_path' do
    context 'when in a cluster scope' do
      let :scope { create(:cluster) }

      it 'finds_the path' do
        dynamic_path = scope.decorate.scope_cases_path
        expect(dynamic_path).to eq(helper.cluster_cases_path(scope))
      end
    end
  end

  describe '#scope_path' do
    subject { scope.decorate.scope_path }

    context 'when in a cluster scope' do
      let :scope { create(:cluster) }

      it 'finds the path' do
        expect(subject).to eq(helper.cluster_path(scope))
      end
    end

    context 'when in a site scope' do
      let :scope { create(:site) }

      before :each do
        allow(h).to receive(:current_user).and_return(user)
      end

      context 'when a contact is signed in' do
        let :user { create(:contact) }

        it 'returns the root path' do
          expect(subject).to eq(helper.root_path)
        end
      end

      context 'when an admin is signed in' do
        let :user { create(:admin) }

        it 'returns the site path' do
          expect(subject).to eq(h.site_path(scope))
        end
      end
    end
  end
end

