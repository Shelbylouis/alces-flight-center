class AddShortcodeAndCaseIndexToCluster < ActiveRecord::Migration[5.1]
  def change
    add_column :clusters, :shortcode, :string  # We want this to be null: false
    # but can't do so until the data migration has been run. We can't set a
    # default because we want it to be unique.
    add_column :clusters, :case_index, :integer, default: 0, null: false

    add_index :clusters, :shortcode, unique: true
  end
end
