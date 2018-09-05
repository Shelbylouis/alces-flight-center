class AddSiteIdentifierToSites < ActiveRecord::Migration[5.2]
  def change
    # column will be set non-nullable in next migration, after defaults have been entered
    add_column :sites, :identifier, :string, null: true 
  end
end
