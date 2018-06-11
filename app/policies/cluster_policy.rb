class ClusterPolicy < ApplicationPolicy

  alias_method :deposit?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
