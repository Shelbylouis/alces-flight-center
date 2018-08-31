class InitialiseAssignedContactsForOpenCases < ActiveRecord::Migration[5.2]
  def change
    Case.active.each do |kase|
      kase.send(:set_assigned_contact)
      kase.save!
    end
  end
end
