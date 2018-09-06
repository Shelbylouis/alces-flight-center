class TopicsController < ApplicationController
  def index
    # Check for `signed_in_without_account?` here as Flight Platform users
    # without a Flight Center account have access to topics.  
    if current_user.nil? && !signed_in_without_account?
      render status: :unauthorized,
        json: { error: 'Authentication required' }
      return
    end

    render json: {
      topics: policy_scope(Topic).all.map do |t|
        {
          title: t.title,
          articles: t.articles.map do |a|
            {
              title: a.title,
              url: a.url,
              meta: a.meta,
            }
          end,
        }
      end
    }
  end
end
