class CreateChangeMotdRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :change_motd_requests do |t|
      t.timestamps null: false

      t.string :motd, null: false
      t.references :case, null: false
    end
  end
end
