
module AdminConfig::ComponentMake
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :default_expansions do
          hide
        end
      end
    end
  end
end
