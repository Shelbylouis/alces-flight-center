module AdminConfig::ClusterCheck
  extend ActiveSupport::Concern

  included do
    rails_admin do
      object_label_method do
        :namespaced_name
      end
    end
  end
end
