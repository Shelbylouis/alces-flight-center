
class TabsBuilder
  def initialize(user:, scope:)
    @user = user
    @scope = scope.decorate
  end

  def overview
    { id: :overview, path: scope.scope_path }
  end

  def cases
    {
      id: :cases, path: scope.scope_cases_path,
      dropdown: [
        new_case_entry,
        current_cases_entry,
        resolved_cases_entry,
      ].compact
    }
  end

  def asset_record
    { id: :asset_record, path: scope.scope_asset_record_path }
  end

  def logs
    { id: :logs, path: scope.scope_logs_path }
  end

  def maintenance
    {
      id: :maintenance,
      path: scope.scope_maintenance_windows_path,
    }
  end

  private

  attr_reader :user, :scope

  def new_case_entry
    if Pundit.policy!(user, Case).create?
      {
        text: 'Create',
        path: scope.new_scope_case_path,
      }
    end
  end

  def current_cases_entry
    {
      text: "Current (#{scope.cases.active.size})",
      path: scope.scope_cases_path,
    }
  end

  def resolved_cases_entry
    {
      text: 'Resolved',
      path: scope.scope_cases_path(state: %w(resolved closed)),
    }
  end
end
