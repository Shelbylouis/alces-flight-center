class CaseCommentPolicy < ApplicationPolicy
  def create?
    record.case.commenting_enabled_for?(user)
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
