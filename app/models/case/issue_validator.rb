
class Case
  class IssueValidator < Validator
    def validate(record)
      @record = record

      validate_issue_allowed_for_cluster_or_part
    end

    private

    def validate_issue_allowed_for_cluster_or_part
      issue_errors_with_conditions.map do |error, condition|
        record.errors.add(:issue, error) if condition
      end
    end

    def issue_errors_with_conditions
      conditional_cluster_issue_errors.merge(
        all_conditional_cluster_part_issue_errors
      )
    end

    def conditional_cluster_issue_errors
      {
        managed_issue_error_for('cluster') => managed_issue_for_advice_cluster?,
        advice_only_issue_error_for('cluster') => advice_only_issue_for_managed_cluster?,
      }
    end

    def all_conditional_cluster_part_issue_errors
      Cluster::PART_NAMES.map do |part_name|
        conditional_cluster_part_issue_errors(part_name)
      end.reduce(:merge)
    end

    def conditional_cluster_part_issue_errors(part_name)
      {
        managed_issue_error_for(part_name) => managed_issue_for_advice_part?(part_name),
        advice_only_issue_error_for(part_name) => advice_only_issue_for_managed_part?(part_name),
      }
    end

    def managed_issue_for_advice_cluster?
      record.issue.managed? && no_parts_required? && record.cluster&.advice?
    end

    def managed_issue_for_advice_part?(part_name)
      record.issue.managed? &&
        part_required?(part_name) &&
        part(part_name)&.advice?
    end

    def managed_issue_error_for(model_type)
      <<-EOF.squish
      is only available for #{SupportType::MANAGED_TEXT}
      #{model_type.to_s.pluralize}, but given #{model_type} is
      #{SupportType::ADVICE_TEXT}
      EOF
    end

    def advice_only_issue_for_managed_cluster?
      record.issue.advice_only? && record.cluster.managed?
    end

    def advice_only_issue_for_managed_part?(part_name)
      record.issue.advice_only? &&
        part_required?(part_name) &&
        part(part_name).managed?
    end

    def advice_only_issue_error_for(model_type)
      <<-EOF.squish
      is only available for #{SupportType::ADVICE_TEXT}
      #{model_type.to_s.pluralize}, but given #{model_type} is
      #{SupportType::MANAGED_TEXT}
      EOF
    end

    def no_parts_required?
      !Cluster::PART_NAMES.map { |part_name| part_required?(part_name) }.any?
    end
  end
end
