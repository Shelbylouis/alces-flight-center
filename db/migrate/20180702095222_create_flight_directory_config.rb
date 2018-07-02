class CreateFlightDirectoryConfig < ActiveRecord::Migration[5.2]
  def change
    create_table :flight_directory_configs do |t|
      t.string :hostname,
        limit: 255,
        null: false

      t.string :username,
        limit: 255,
        null: false

      t.references :site,
        foreign_key: true,
        null: false

      t.timestamps
    end
  end
end
