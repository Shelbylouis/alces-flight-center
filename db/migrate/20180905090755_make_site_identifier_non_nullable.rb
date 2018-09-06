class MakeSiteIdentifierNonNullable < ActiveRecord::Migration[5.2]
  def change
      change_column_null :sites, :identifier, false
  end
end
