class FlightDirectoryConfigPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.contact?
        scope.
          joins(site: :users).
          where(users: {id: user.id})
      else
        scope.none
      end
    end
  end
end
