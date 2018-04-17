class CreateCaseStateTransitions < ActiveRecord::Migration[5.1]
  def change
    create_table :case_state_transitions do |t|
      t.references :case, foreign_key: true, null:false, index: true
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
