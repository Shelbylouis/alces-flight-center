class SetTokenAndSubjectForExistingCases < ActiveRecord::DataMigration
  def up
    Case.all.each do |support_case|
      support_case.send(:generate_token)
      support_case.send(:assign_default_subject_if_unset)
      support_case.save!
    end
  end
end
