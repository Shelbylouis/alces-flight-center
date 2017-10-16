
module Component::AdminConfig
  extend ActiveSupport::Concern

  included do
    rails_admin do

      show do
        configure :asset_record_view do
          label 'Asset record'
          show
        end
      end

    end
  end
end
