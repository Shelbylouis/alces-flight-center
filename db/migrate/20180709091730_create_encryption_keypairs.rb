class CreateEncryptionKeypairs < ActiveRecord::Migration[5.2]
  def change
    create_table :encryption_keys do |t|
      t.text :public_key, limit: 8 * 1024

      t.timestamps null: false
    end
  end
end
