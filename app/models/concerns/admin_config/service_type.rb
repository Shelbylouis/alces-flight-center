
module AdminConfig::ServiceType
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :description, :text do
          html_attributes rows: 10, cols: 100
        end

        configure :automatic do
          help <<~EOF
            An instance of an 'automatic' Service will automatically be created
            and associated with every new Cluster; non-automatic Services must
            be individually created for Clusters.
          EOF
        end

        configure :services do
          hide
        end
      end
    end
  end
end
