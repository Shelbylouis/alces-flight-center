class AddAdminUsers < ActiveRecord::Migration[5.1]
  def change
    rename_table :contacts, :users

    add_column :users, :admin, :boolean, null: false, default: false
    reversible do |migration|
      migration.down do
        # Delete all cases, as changing `contact` -> `user` breaks things
        # otherwise, and delete admin users (users without site) as reverting
        # site to be non-nullable will break without doing this.
        execute <<-SQL
          DELETE FROM cases;
          DELETE FROM users WHERE site_id IS NULL;
        SQL
      end
      change_column_null :users, :site_id, true
    end

    remove_reference :cases, :contact
    add_reference :cases, :user, foreign_key: true
  end
end
