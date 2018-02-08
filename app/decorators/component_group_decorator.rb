class ComponentGroupDecorator < ApplicationDecorator
  include AssetRecordDecorator

  delegate_all

  decorates_association :components

  def path
    h.component_group_path(self)
  end

  def link
    component_name = h.pluralize(components.length, component_type.name)
    h.link_to "#{name} — #{component_name}", path
  end
end
