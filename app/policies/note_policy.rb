class NotePolicy < ApplicationPolicy

  def permitted?
    case @record.visibility
    when 'engineering'
      admin?
    else
      editor?
    end
  end

  alias_method :create?, :editor?
  alias_method :new?, :editor?
  alias_method :set_visibility?, :admin?
  alias_method :edit?, :permitted?
  alias_method :update?, :permitted?

  class Scope < Scope
    def resolve
      scope
    end
  end
end
