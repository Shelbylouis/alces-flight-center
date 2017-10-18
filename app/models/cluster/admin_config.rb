
module Cluster::AdminConfig
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
      end

    end
  end
end
