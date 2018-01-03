class ComponentGroupDecorator < ApplicationDecorator
  include ActionView::Helpers::TextHelper

  delegate_all
  decorates_association :components

  def link_text
    "#{name} — #{pluralize(components.length, component_type.name)}"
  end
end
