class ChangeMotdRequestPolicy < ApplicationPolicy
  alias_method :apply?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
