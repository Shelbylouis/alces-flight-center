class NotePolicy < ApplicationPolicy

  def permitted?
    case @record.flavour
    when 'engineering'
      admin?
    else
      editor?
    end
  end

  alias_method :create?, :permitted?
  alias_method :edit?, :permitted?
  alias_method :update?, :permitted?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
