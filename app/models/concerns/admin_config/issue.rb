
module AdminConfig::Issue
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :details_template, :text do
          html_attributes rows: 5, cols: 100
        end
      end
    end
  end
end
