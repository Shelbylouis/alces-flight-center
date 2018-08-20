class SetInitialNoteTitles < ActiveRecord::Migration[5.2]

  class Note < ApplicationRecord
  end

  def up
    Note.all.each do |note|
      note.title = note.flavour == 'customer' ? 'Customer notes' : 'Engineering notes'
      note.save!
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
