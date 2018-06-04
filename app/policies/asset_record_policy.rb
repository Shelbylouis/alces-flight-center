class AssetRecordPolicy < ApplicationPolicy
  alias_method :update?, :admin?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
