class AddOrderingToComponentTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :component_types,
      :ordering,
      :integer,
      required: true
  end
end
