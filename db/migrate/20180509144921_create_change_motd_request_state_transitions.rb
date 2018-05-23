class CreateChangeMotdRequestStateTransitions < ActiveRecord::Migration[5.1]
  def change
    add_column :change_motd_requests, :state, :text, null: false

    create_table :change_motd_request_state_transitions do |t|
      # Override default name as this goes over index name limit (62
      # characters).
      t.references :change_motd_request,
        foreign_key: true,
        null: false,
        index: {name: 'index_cmrst_on_cmr_id'}

      t.string :namespace
      t.string :event
      t.string :from
      t.string :to, null: false
      t.timestamp :created_at, null: false

      # Custom field not required by state_machines-audit_trail Gem.
      t.references :user, foreign_key: true, null: false
    end
  end
end
