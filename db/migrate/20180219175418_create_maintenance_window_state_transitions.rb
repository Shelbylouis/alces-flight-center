class CreateMaintenanceWindowStateTransitions < ActiveRecord::Migration[5.1]
  def change
    # Initial version of this migration generated using `rails generate
    # state_machines:audit_trail MaintenanceWindow state`.
    create_table :maintenance_window_state_transitions do |t|
      t.timestamp :created_at, null: false

      # Override default name as this goes over index name limit (62
      # characters).
      t.references :maintenance_window,
        foreign_key: true,
        null: false,
        index: {name: 'index_mwst_on_mw_id'}

      t.string :namespace
      t.string :event
      t.string :from
      t.string :to, null: false

      # Custom field not required by state_machines-audit_trail Gem.
      t.references :user, foreign_key: true, null: true
    end
  end
end
