
module AdminConfig::Component
  extend ActiveSupport::Concern

  included do
    rails_admin do
      object_label_method do
        :namespaced_name
      end

      edit do
        configure :cluster do
          hide
        end
        configure :cases do
          hide
        end
        configure :maintenance_windows do
          hide
        end
        configure :logs do
          hide
        end
      end
    end
  end
end
