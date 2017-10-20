
module AdminConfig::Case
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :rt_ticket_id do
          hide
        end
        configure :details, :text do
          html_attributes rows: 10, cols: 100
        end
      end
    end
  end

end
