
class Case::Validator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    PART_NAMES.each do |part_name|
      validate_correct_cluster_part_relationship(part_name)
    end
    validate_issue_allowed_for_cluster_or_part
  end

  private

  PART_NAMES = [:component, :service].freeze

  def validate_correct_cluster_part_relationship(part_name)
    part = part(part_name)
    error = if part_required?(part_name)
              if !part
                "issue requires a #{part_name} but one was not given"
              elsif part.cluster != record.cluster
                "given #{part_name} is not part of given cluster"
              end
            elsif part
              "issue does not require a #{part_name} but one was given"
            end
    record.errors.add(part_name, error) if error
  end

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
    PART_NAMES.map do |part_name|
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
    !PART_NAMES.map { |part_name| part_required?(part_name) }.any?
  end

  def part_required?(part_name)
    record.issue.send("requires_#{part_name}")
  end

  def part(part_name)
    record.send(part_name)
  end
end
