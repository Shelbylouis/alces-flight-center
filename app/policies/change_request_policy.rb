class ChangeRequestPolicy < ApplicationPolicy

  alias_method :create?, :admin?
  alias_method :edit?, :admin?
  alias_method :update?, :admin?
  alias_method :propose?, :admin?
  alias_method :handover?, :admin?
  alias_method :cancel?, :admin?

  alias_method :authorise?, :contact?
  alias_method :decline?, :contact?
  alias_method :complete?, :contact?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
