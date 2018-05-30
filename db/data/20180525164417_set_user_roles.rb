class SetUserRoles < ActiveRecord::Migration[5.2]
  def up
    User.all.each do |user|
      role = if user.admin
               :admin
             elsif user.primary_contact
               :primary_contact
             else
               :secondary_contact
             end

      user.update!(role: role)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
