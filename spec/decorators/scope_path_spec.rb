require 'rails_helper'

RSpec.describe 'scope_path decorator methods' do
  # Allow a user to be logged in only when required
  let(:user) { nil }
  before :each do
    allow(h).to receive(:current_user).and_return(user) if user
  end

  context 'in a cluster scope' do
    let(:scope) { create(:cluster).decorate }

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
    subject { scope.decorate.scope_cases_path }

    context 'when in a cluster scope' do
      let(:scope) { create(:cluster) }

      it 'finds_the path' do
        expect(subject).to eq(helper.cluster_cases_path(scope))
      end
    end

    context 'when in site scope and a contact is signed in' do
      let(:user) { create(:contact) }
      let(:scope) { create(:site) }

      it 'returns the cases path' do
        expect(subject).to eq(helper.cases_path)
      end
    end
  end

  describe '#scope_path' do
    subject { scope.decorate.scope_path }

    context 'when in a cluster scope' do
      let(:scope) { create(:cluster) }

      it 'finds the path' do
        expect(subject).to eq(helper.cluster_path(scope))
      end
    end

    context 'when in a site scope' do
      let(:scope) { create(:site) }

      context 'when a contact is signed in' do
        let(:user) { create(:contact) }

        it 'returns the root path' do
          expect(subject).to eq(helper.root_path)
        end
      end

      context 'when an admin is signed in' do
        let(:user) { create(:admin) }

        it 'returns the site path' do
          expect(subject).to eq(h.site_path(scope))
        end
      end
    end
  end

  context 'with key word inputs arguments' do
    let(:input) { { key: 'value' } }
    let(:scope) { create(:cluster) }
    subject { scope.decorate.scope_path(**input) }

    it 'uses them as path parameters' do
      expect(subject).to eq(h.cluster_path(scope, **input))
    end
  end
end

