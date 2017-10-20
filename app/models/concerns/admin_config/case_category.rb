
module AdminConfig::CaseCategory
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :issues do
          hide
        end
      end
    end
  end
end
