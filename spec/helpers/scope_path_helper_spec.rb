require 'rails_helper'

RSpec.describe ScopePathHelper do
  describe '#respond_to' do
    it 'responds to #scope_path' do
      expect(helper.respond_to? :scope_path).to eq(true)
    end

    it 'does not respond to #_scope_path' do
      expect(helper.respond_to? :_scope_path).to eq(false)
    end
  end

  context 'when in a cluster scope' do
    let :scope { create(:cluster) }

    describe '#scope_path' do
      it 'finds the path' do
        expect(helper.scope_path(scope)).to eq(helper.cluster_path(scope))
      end
    end
  end
end

