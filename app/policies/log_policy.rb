class LogPolicy < ApplicationPolicy
  alias_method :index?, :anyone?

  alias_method :create?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
