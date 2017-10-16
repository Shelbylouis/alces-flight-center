class CreateAdditionalContacts < ActiveRecord::Migration[5.1]
  def change
    create_table :additional_contacts do |t|
      t.string :email, null: false
      t.belongs_to :site, null: false

      t.timestamps null: false
    end
  end
end
