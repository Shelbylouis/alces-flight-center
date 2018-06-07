class MaintenanceWindowPolicy < ApplicationPolicy
  alias_method :create?, :admin?
  alias_method :cancel?, :admin?
  alias_method :end?, :admin?
  alias_method :extend?, :admin?

  alias_method :confirm?, :editor?
  alias_method :confirm_submit?, :editor?

  alias_method :reject?, :contact?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
