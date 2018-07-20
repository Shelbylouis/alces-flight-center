require 'rails_helper'

RSpec.describe TopicPolicy do
  include_context 'policy'

  let(:resolved_scope) do
    described_class::Scope.new(user, Topic.all).resolve
  end

  let!(:site) { create(:site) }
  let!(:another_site) { create(:site) }
  let!(:global_topics) { create_list(:global_topic, 2) }
  let!(:site_topics) { create_list(:site_topic, 2, site: site) }
  let!(:other_site_topics) { create_list(:site_topic, 2, site: another_site) }

  context 'when the user is an admin' do
    let(:user) { admin }

    it 'resolves all global topics only' do
      expect(resolved_scope.order(:id)).to eq(global_topics)
    end
  end

  context 'when the user is not an admin' do
    let(:user) { site_contact }

    it 'resolves global and site topics' do
      expect(resolved_scope.order(:id)).to eq(global_topics + site_topics)
    end

    it 'does not resolves other site topics' do
      other_site_topics.each do |topic|
        expect(resolved_scope.order(:id)).to_not include(topic)
      end
    end
  end
end
