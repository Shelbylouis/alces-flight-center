
class Case
  class IssueValidator < ActiveModel::Validator
    def validate(record)
      if record.issue.respond_to?(:administrative?) && record.issue.administrative?
        unless record.maintenance_windows.unfinished.empty?
          record.errors.add(:issue, 'cannot be administrative if there are unfinished maintenance windows')
        end
      end
    end
  end
end
