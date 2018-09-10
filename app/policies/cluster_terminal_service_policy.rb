class ClusterTerminalServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope
      elsif user.contact?
        scope.
          joins(cluster: { site: :users }).
          where(users: {id: user.id})
      else
        scope.none
      end
    end
  end
end
