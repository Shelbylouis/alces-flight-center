class ComponentGroupDecorator < ApplicationDecorator
  delegate_all
  decorates_association :components

  def link
    t = "#{name} — #{h.pluralize(components.length, component_type.name)}"
    h.link_to t, h.component_group_path(self)
  end
end
