
module AdminConfig::Case
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :details, :text do
          html_attributes rows: 10, cols: 100
        end

        configure :rt_ticket_id do
          hide
        end
        configure :last_known_ticket_status do
          hide
        end
        configure :credit_charge do
          hide
        end
      end
    end
  end

end
