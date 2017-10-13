
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

    end
  end
end
