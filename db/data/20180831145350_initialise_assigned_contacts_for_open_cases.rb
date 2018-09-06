class InitialiseAssignedContactsForOpenCases < ActiveRecord::Migration[5.2]
  def change
    Case.reset_column_information
    Case.active.each do |kase|
      next if kase.administrative?
      user = kase.user

      kase.without_auditing do
        kase.contact = if user.contact?
                         user
                       else
                         kase.site.primary_contact
                       end

        kase.save!
      end
    end
  end
end
