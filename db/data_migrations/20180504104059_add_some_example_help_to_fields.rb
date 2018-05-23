class AddSomeExampleHelpToFields < ActiveRecord::DataMigration
  def up
    gridware_issue = Issue.find_by_name!('From available Alces Gridware')
    tier_2 = gridware_issue.tiers.find_by_level!(2)
    tier_2.fields[1].merge!(help: 'E.g. python3')
    tier_2.fields[2].merge!(help: 'E.g. v3.6.4')
    tier_2.fields[3].merge!(help: 'E.g. /home/you/myscript.py')
    tier_2.save!
  end
end
