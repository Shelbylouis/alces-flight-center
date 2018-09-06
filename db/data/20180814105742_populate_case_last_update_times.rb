class PopulateCaseLastUpdateTimes < ActiveRecord::Migration[5.2]

  # These are the fields that, at time of writing this migration,
  # trigger an email update to the customer when edited.
  RELEVANT_AUDIT_FIELDS = %w(issue_id subject).freeze

  def up
    Case.all.each do |kase|
      if kase.open?
        kase.last_update = calculate_last_update(kase)
      else
        # The last admin action will have been to resolve or close the case;
        # so let's use the ActiveRecord updated_at value.
        kase.last_update = kase.updated_at
      end
      kase.save!
    end
  end

  def down
    Case.all.each do |kase|
      kase.last_update = nil
      kase.save!
    end
  end

  private

  def calculate_last_update(kase)
    [
      last_admin_comment(kase),
      last_maintenance_window_transition(kase),
      last_cr_transition(kase),
      last_relevant_audit(kase),
    ].compact.max
  end

  def last_admin_comment(kase)
    kase.case_comments
        .joins(:user)
        .where(users: { role: 'admin' })
        .order(:created_at)
        .last
        &.created_at
  end

  def last_maintenance_window_transition(kase)
    kase.maintenance_windows
        .map(&:transitions)
        .flatten
        .sort_by(&:created_at)
        .select(&:event)
        .last
        &.created_at
  end

  def last_cr_transition(kase)
    return unless kase.change_request.present?
    kase.change_request
        .transitions
        .order(:created_at)
        .last
        &.created_at
  end

  def last_relevant_audit(kase)
    kase.audits
        .order(:created_at)
        .select { |a|
          RELEVANT_AUDIT_FIELDS.include?(a.audited_changes.keys.flatten[0])
        }
        .last
        &.created_at
  end
end
