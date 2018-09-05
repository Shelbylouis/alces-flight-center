class SetSiteIdentifiers < ActiveRecord::Migration[5.2]
  def up
    Site.reset_column_information
    Site.all.each do |site|
      if site.identifier.blank?
        site.identifier = site.name
        site.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
