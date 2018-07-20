require 'rails_helper'

RSpec.describe TopicsController, type: :request do
  describe 'index' do
    let(:path) { topics_path(as: user) }
    let(:site) { create(:site) }
    let(:site_contact) { create(:contact, site: site) }
    let(:another_site) { create(:site) }
    let!(:global_topics) { create_list(:global_topic, 2, :with_articles) }
    let!(:site_topics) { create_list(:site_topic, 2, site: site) }
    let!(:other_site_topics) { create_list(:site_topic, 2, site: another_site) }

    context 'when no user' do
      let(:user) { nil }

      it 'responds with unauthorized' do
        get(path)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user is present' do
      let(:user) { site_contact }
      let(:response_json) {
        JSON.parse(response.body).with_indifferent_access
      }

      it 'responds successfully' do
        get(path)
        expect(response).to have_http_status(:ok)
      end

      it 'includes only global or correct site topics' do
        expected_topics = (global_topics + site_topics).map do |topic|
          { title: topic.title }
        end

        get(path)

        response_json['topics'].each do |topic|
          expect(expected_topics).to include({ title: topic['title'] })
        end
      end

      it 'does not include topics for other sites' do
        get(path)

        response_topics = (response_json['topics']).map do |topic|
          { title: topic['title'] }
        end
        (global_topics + site_topics).each do |topic|
          expect(response_topics).to include({ title: topic.title })
        end
      end

      it 'includes all articles for the topics' do
        expected_articles = global_topics
          .map do |topic|
            topic.articles
          end
          .flatten
          .map do |article|
            {
              title: article.title,
              url: article.url,
              meta: article.meta,
            }.stringify_keys
          end

        get(path)

        response_articles = response_json['topics'].reduce([]) do |accum, topic|
          accum.concat(topic['articles'])
        end

        expect(response_articles).to eq(expected_articles)
      end
    end
  end
end
