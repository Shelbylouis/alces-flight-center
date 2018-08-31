class InitialiseAssignedContactsForOpenCases < ActiveRecord::Migration[5.2]
  def change
    open_cases = Case.all.active

    open_cases.each do |kase|
      user = kase.user

      if user.admin?
        kase.contact = kase.site.primary_contact
      else
        kase.contact = user
      end

      kase.save
    end
  end
end
