
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
        { text: "Current (#{scope.cases.active.size})", path: scope.scope_cases_path },
        { text: 'Resolved', path: scope.resolved_scope_cases_path }
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
      admin_dropdown: [
        {
          text: 'Pending',
          path: scope.scope_maintenance_windows_path
        }, {
          text: 'Request',
          path: scope.new_scope_maintenance_window_path
        }
      ]
    }
  end

  private

  attr_reader :user, :scope

  def new_case_entry
    if user.editor?
      {
        text: 'Create',
        path: scope.new_scope_case_path,
      }
    end
  end
end
