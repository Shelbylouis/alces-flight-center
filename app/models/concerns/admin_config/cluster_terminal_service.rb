module AdminConfig::ClusterTerminalService
  extend ActiveSupport::Concern

  included do
    include AdminConfig::TerminalService

    rails_admin do
      edit do
        configure :site_id do
          hide
        end
      end
    end
  end
end
