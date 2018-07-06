class ClusterPolicy < ApplicationPolicy

  alias_method :deposit?, :admin?
  alias_method :check_results?, :admin?
  alias_method :check_submission?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
