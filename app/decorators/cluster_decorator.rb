class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :component_groups
end
