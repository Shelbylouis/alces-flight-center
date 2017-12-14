class TweakIssueNames < ActiveRecord::DataMigration
  def up
    Issue.find_by_name('Hardware issue').update!(name: 'Suspected hardware issue')
    Issue.find_by_name('Service issue').update!(name: 'Suspected service issue')
  end
end
