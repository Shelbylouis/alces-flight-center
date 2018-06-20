class CreateChangeRequestStateTransitions < ActiveRecord::Migration[5.2]
  def change
    create_table :change_request_state_transitions do |t|
      t.references :change_request, foreign_key: true
      t.string :namespace
      t.string :event
      t.string :from
      t.string :to
      t.timestamp :created_at

      # Custom field not required by state_machines-audit_trail Gem.
      t.references :user, foreign_key: true, null: false
    end
  end
end
