class CreateCaseComments < ActiveRecord::Migration[5.1]
  def change
    create_table :case_comments do |t|
      t.references :user, foreign_key: true, null: false
      t.references :case, foreign_key: true, null: false
      t.string :text, null: false

      t.timestamps null: false
    end
  end
end
