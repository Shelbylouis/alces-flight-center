class PopulateComponentTypes < ActiveRecord::Migration[5.2]

  class ComponentType < ApplicationRecord; end

  class ComponentMake < ApplicationRecord
    belongs_to :component_type
  end

  class ComponentGroup < ApplicationRecord
    belongs_to :component_make
    belongs_to :cluster
  end

  class Component < ApplicationRecord
    belongs_to :component_group
    has_one :cluster, through: :component_group
  end

  def up
    Component.reset_column_information
    Component.all.each do |component|
      component.component_type = component.component_group.component_make.component_type.name
      component.save!
    end
  end

  def down
    # pass
  end
end
