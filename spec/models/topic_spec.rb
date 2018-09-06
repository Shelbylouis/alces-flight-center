require 'rails_helper'

RSpec.describe Topic, type: :model do
  describe 'scope' do
    let(:site) { create(:site) }

    describe 'global scope' do
      it 'cannot belong to a site' do
        topic = build(:topic, scope: 'global', site: site)
        expect(topic).to_not be_valid
        expect(topic.errors.added?(:scope, :inclusion)).to be(true)
      end
    end

    describe 'site scope' do
      it 'must belong to a site' do
        topic = build(:topic, scope: 'site', site: nil)
        expect(topic).to_not be_valid
        expect(topic.errors.added?(:scope, :inclusion)).to be(true)
      end
    end
  end

  describe 'permissions_check_unneeded?' do
    it 'is unneeded when the topic is global' do
      topic = build(:global_topic)
      expect(topic.send(:permissions_check_unneeded?)).to be(true)
    end

    it 'is needed when the topic is not global' do
      RequestStore.store[:current_user] = create(:user)
      topic = build(:site_topic)
      expect(topic.send(:permissions_check_unneeded?)).to be_falsey
    end
  end
end
