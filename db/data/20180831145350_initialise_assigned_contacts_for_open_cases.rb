class InitialiseAssignedContactsForOpenCases < ActiveRecord::Migration[5.2]
  def change

    Case.active.each do |kase|
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
