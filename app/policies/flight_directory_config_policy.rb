class FlightDirectoryConfigPolicy < ApplicationPolicy
  def show?
    scope.exists? && user.contact?
  end

  class Scope < Scope
    def resolve
      scope.
        joins(site: :users).
        where(users: {id: user.id})
    end
  end
end
