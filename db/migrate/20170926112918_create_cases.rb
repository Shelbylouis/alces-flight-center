class CreateCases < ActiveRecord::Migration[5.1]
  def change
    create_table :cases do |t|
      t.string :details, null: false

      t.timestamps null: false
    end

    add_reference :cases, :case_category, foreign_key: true
    add_reference :cases, :cluster, foreign_key: true
    add_reference :cases, :component, foreign_key: true
    add_reference :cases, :contact, foreign_key: true
  end
end
