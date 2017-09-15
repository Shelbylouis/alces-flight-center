class AddSiteRefToContacts < ActiveRecord::Migration[5.1]
  def change
    add_reference :contacts, :site, foreign_key: true
  end
end
