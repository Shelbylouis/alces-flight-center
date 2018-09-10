module AdminConfig::SiteTerminalService
  extend ActiveSupport::Concern

  included do
    include AdminConfig::TerminalService
    rails_admin do
      edit do
        configure :cluster_id do
          hide
        end
      end
    end
  end
end
