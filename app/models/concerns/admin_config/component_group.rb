
module AdminConfig::ComponentGroup
  extend ActiveSupport::Concern

  included do
    rails_admin do
      object_label_method do
        :namespaced_name
      end

      edit do

        configure :components do
          hide
        end
        configure :site do
          hide
        end
      end
    end
  end
end
