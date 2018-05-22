class AddNeededNullConstraints < ActiveRecord::Migration[5.1]
  def change
    change_column_null :cases, :tier_level, false
    change_column_null :cases, :display_id, false
    change_column_null :clusters, :shortcode, false
  end
end
