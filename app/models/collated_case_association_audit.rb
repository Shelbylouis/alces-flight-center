class CollatedCaseAssociationAudit

  attr_accessor :user
  attr_accessor :created_at

  def initialize(user_id, created_at, audits)
    @user = User.find(user_id)
    @created_at = created_at
    @audits = audits
  end

  def decorate
    CollatedCaseAssociationAuditDecorator.new(self)
  end

  def additions
    @additions ||= map_audits_to_models(
      @audits.select { |a| a.action == 'create' }
    )
  end

  def deletions
    @deletions ||= map_audits_to_models(
      @audits.select { |a| a.action == 'destroy' }
    )
  end

  private

  def map_audits_to_models(audits)
    audits.map { |a|
      Kernel.const_get(a.audited_changes['associated_element_type'])
          .find(a.audited_changes['associated_element_id'])
    }
  end
end
