
module Site::AdminConfig
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :description do
          html_attributes rows: 10, cols: 100
          help Constants::MARKDOWN_DESCRIPTION_EDIT_HELP
        end

        configure :canonical_name do
          hide
        end
        configure :users do
          hide
        end
        configure :clusters do
          hide
        end
        configure :cases do
          hide
        end
        configure :components do
          hide
        end
        configure :additional_contacts do
          hide
        end
      end
    end
  end
end
