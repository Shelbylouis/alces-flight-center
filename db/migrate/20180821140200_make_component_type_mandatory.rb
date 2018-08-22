class MakeComponentTypeMandatory < ActiveRecord::Migration[5.2]
  def change
    change_column_null :components, :component_type, false
  end
end
