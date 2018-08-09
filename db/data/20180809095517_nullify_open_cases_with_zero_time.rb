class NullifyOpenCasesWithZeroTime < ActiveRecord::Migration[5.2]
  def up
    Case.active.where(time_worked: 0).each do |k|
      k.without_auditing do
        k.time_worked = nil
        k.save!
      end
    end
  end

  def down
    Case.active.where(time_worked: nil).each do |k|
      k.without_auditing do
        k.time_worked = 0
        k.save!
      end
    end
  end
end
