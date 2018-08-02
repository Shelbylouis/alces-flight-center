class ClusterPolicy < ApplicationPolicy

  alias_method :deposit?, :admin?
  alias_method :save_check_results?, :admin?
  alias_method :enter_check_results?, :admin?
  alias_method :view_checks?, :admin?
  alias_method :preview?, :admin?
  alias_method :write?, :admin?
  alias_method :create?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
