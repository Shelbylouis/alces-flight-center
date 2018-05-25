class SetCaseDisplayIds < ActiveRecord::DataMigration
  def up
    Case.all.each do |kase|
      kase.send :set_display_id
      kase.save!
    end
  end
end
