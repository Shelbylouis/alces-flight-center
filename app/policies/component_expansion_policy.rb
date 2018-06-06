class ComponentExpansionPolicy < ApplicationPolicy
  alias_method :create?, :admin?
  alias_method :update?, :admin?
  alias_method :destroy?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
