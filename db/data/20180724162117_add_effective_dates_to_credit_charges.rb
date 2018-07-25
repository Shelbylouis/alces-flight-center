class AddEffectiveDatesToCreditCharges < ActiveRecord::Migration[5.2]
  def up
    CreditCharge.all.each do |cc|
      cc.send(:set_effective_date)
      cc.save!
    end
  end

  def down
    # pass
  end
end
