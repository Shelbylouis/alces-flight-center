class ComponentGroupDecorator < ApplicationDecorator
  delegate_all
  decorates_association :components
end
