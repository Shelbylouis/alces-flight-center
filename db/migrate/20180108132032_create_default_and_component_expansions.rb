class CreateDefaultAndComponentExpansions < ActiveRecord::Migration[5.1]
  def change
    add_reference :expansions, :component_make, foreign_key: true
    add_reference :expansions, :component, foreign_key: true
  end
end
