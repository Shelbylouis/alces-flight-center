class CasePolicy < ApplicationPolicy
  alias_method :create?, :editor?

  def escalate?
    editor? && !@record.issue&.administrative?
  end

  alias_method :close?, :admin?
  alias_method :assign_engineer?, :admin?

  alias_method :resolve?, :admin?
  alias_method :set_time?, :admin?
  alias_method :set_tier?, :admin?
  alias_method :set_commenting?, :admin?
  alias_method :edit_associations?, :admin?
  alias_method :edit?, :admin?

  def redirect_to_canonical_path?
    true
  end

  def update?
    user.admin? || record.site.users.include?(user)
  end

  def assign_contact?
    unless record.administrative?
      user.admin? | user.contact?
    end
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
