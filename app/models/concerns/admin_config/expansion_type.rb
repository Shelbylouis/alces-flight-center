
module AdminConfig::ExpansionType
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :expansions do
          hide
        end
      end
    end
  end
end
