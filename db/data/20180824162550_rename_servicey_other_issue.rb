class RenameServiceyOtherIssue < ActiveRecord::Migration[5.2]

  OLD_NAME = 'Other'.freeze
  NEW_NAME = 'Other (related to service)'.freeze

  def up
    other = Issue.find_by(name: OLD_NAME, requires_service: true)
    other.name = NEW_NAME
    other.save!
  end

  def down
    other = Issue.find_by(name: NEW_NAME)
    other.name = OLD_NAME
    other.save!
  end
end
