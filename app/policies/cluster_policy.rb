class ClusterPolicy < ApplicationPolicy

  alias_method :deposit?, :admin?
  alias_method :check_results?, :admin?
  alias_method :check_submission?, :admin?
  alias_method :preview?, :admin?
  alias_method :write?, :admin?
  alias_method :create?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
