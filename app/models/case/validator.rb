
class Case::Validator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    validate_correct_component_relationship
    validate_issue_allowed_for_cluster_or_component
  end

  private

  def validate_correct_component_relationship
    if record.issue.requires_component
      if !record.component
        record.errors.add(:component, 'issue requires a component but one was not given')
      elsif record.component.cluster != record.cluster
        record.errors.add(:component, 'given component is not part of given cluster')
      end
    elsif record.component
      record.errors.add(:component, 'issue does not require a component but one was given')
    end
  end

  def validate_issue_allowed_for_cluster_or_component
    if record.issue.managed?
      if record.issue.requires_component
        if record.component&.advice?
          record.errors.add(:issue, managed_issue_for_advice_component_error)
        end
      elsif record.cluster.advice?
        record.errors.add(:issue, managed_issue_for_advice_cluster_error)
      end
    elsif record.issue.advice_only?
      if record.issue.requires_component
        if record.component.managed?
          record.errors.add(:issue, advice_only_issue_for_managed_component_error)
        end
      elsif record.cluster.managed?
        record.errors.add(:issue, advice_only_issue_for_managed_cluster_error)
      end
    end
  end

  def managed_issue_for_advice_cluster_error
    managed_issue_error_for('cluster')
  end

  def managed_issue_for_advice_component_error
    managed_issue_error_for('component')
  end

  def managed_issue_error_for(model_type)
    <<-EOF.squish
      is only available for #{SupportType::MANAGED_TEXT}
      #{model_type.pluralize}, but given #{model_type} is
      #{SupportType::ADVICE_TEXT}
    EOF
  end

  def advice_only_issue_for_managed_component_error
    advice_only_issue_error_for('component')
  end

  def advice_only_issue_for_managed_cluster_error
    advice_only_issue_error_for('cluster')
  end

  def advice_only_issue_error_for(model_type)
    <<-EOF.squish
      is only available for #{SupportType::ADVICE_TEXT}
      #{model_type.pluralize}, but given #{model_type} is
      #{SupportType::MANAGED_TEXT}
    EOF
  end
end
