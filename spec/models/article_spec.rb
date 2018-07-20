require 'rails_helper'

RSpec.describe Article, type: :model do
  describe 'permissions_check_unneeded?' do
    it 'is unneeded when the owning topic is global' do
      topic = build(:global_topic)
      article = build(:article, topic: topic)
      expect(article.send(:permissions_check_unneeded?)).to be(true)
    end

    it 'is needed when the owning topic is not global' do
      RequestStore.store[:current_user] = create(:user)
      topic = build(:site_topic)
      article = build(:article, topic: topic)
      expect(article.send(:permissions_check_unneeded?)).to be_falsey
    end
  end
end
