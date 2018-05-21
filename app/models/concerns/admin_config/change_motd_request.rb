
module AdminConfig::ChangeMotdRequest
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :change_motd_request_state_transitions do
          hide
        end
      end
    end
  end

end
