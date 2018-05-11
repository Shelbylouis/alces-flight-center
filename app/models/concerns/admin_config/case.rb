
module AdminConfig::Case
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :rt_ticket_id do
          hide
        end
        configure :last_known_ticket_status do
          hide
        end
        configure :token do
          hide
        end
        configure :maintenance_windows do
          hide
        end
      end
    end
  end

end
