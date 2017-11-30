class SiteDecorator < ApplicationDecorator
  delegate_all
  decorates_association :clusters
end
