class CasePolicy < ApplicationPolicy
  def index?
    true
  end
  alias_method :resolved?, :index?

  alias_method :create?, :editor?
  alias_method :escalate?, :editor?

  alias_method :close?, :admin?
  alias_method :assign?, :admin?
  alias_method :resolve?, :admin?
  alias_method :set_time?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
