class AdjustCreditChargeCreationDates < ActiveRecord::Migration[5.2]
  def up
    # See https://alces.slack.com/archives/C72GT476Y/p1530551064000218
    # The aim of this code is to set the created_at date of credit charges to
    # the date at which its associated Case was resolved.
    #
    # For cases resolved in RT, this will be their completed_at date; otherwise
    # the date of creation of the transition for the 'resolve' event. Failing that
    # we fall back to the case creation date (which is probably closer to the
    # desired date than its date of being closed).
    Case.all.each do |c|
      if cch = c.credit_charge
        cst = c.case_state_transitions.find{|o| o.event == 'resolve'}
        cch.created_at =
          if cst.nil?
            c.completed_at || c.created_at
          else
            cst.created_at
          end
        cch.save!
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
