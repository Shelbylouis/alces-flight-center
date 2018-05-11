
module AdminConfig::Cluster
  extend ActiveSupport::Concern

  included do
    rails_admin do
      configure :canonical_name do
        hide
      end

      show do
        configure :documents_path do
          show
        end
      end

      edit do
        configure :description do
          html_attributes rows: 10, cols: 100
          help Constants::MARKDOWN_DESCRIPTION_EDIT_HELP
        end

        configure :canonical_name do
          hide
        end
        configure :component_groups do
          hide
        end
        configure :components do
          hide
        end
        configure :cases do
          hide
        end
        configure :services do
          hide
        end
        configure :maintenance_windows do
          hide
        end
      end
    end
  end
end
