class AddEffectiveDatesToCreditDeposits < ActiveRecord::Migration[5.2]
  def up
    CreditDeposit.all.each do |cd|
      cd.effective_date = cd.created_at
      cd.save!
    end
  end

  def down
    # pass
  end
end
