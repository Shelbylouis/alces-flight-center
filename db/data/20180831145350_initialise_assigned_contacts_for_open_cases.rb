class InitialiseAssignedContactsForOpenCases < ActiveRecord::Migration[5.2]
  def change

    Case.active.each do |kase|
      user = kase.user

      kase.without_auditing do
        if user.admin?
          kase.contact = kase.site.primary_contact
        else
          kase.contact = user
        end

        kase.save!
      end
    end
  end
end
