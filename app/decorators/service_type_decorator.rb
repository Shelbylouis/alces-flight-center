class ServiceTypeDecorator < ApplicationDecorator
  delegate_all
  decorates_association :issues
end
