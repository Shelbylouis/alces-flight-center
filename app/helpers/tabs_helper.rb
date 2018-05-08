module TabsHelper
  class TabsBuilder
    def initialize(scope)
      @scope = scope.decorate
    end

    def overview
      { id: :overview, path: scope.scope_path }
    end

    def cases
      {
        id: :cases, path: scope.scope_cases_path,
        dropdown: [
          { text: 'Current', path: scope.scope_cases_path },
          { text: 'Resolved', path: scope.resolved_scope_cases_path }
        ]
      }
    end

    def asset_record
      { id: :asset_record, path: scope.scope_asset_record_path }
    end

    def logs
      { id: :logs, path: scope.scope_logs_path }
    end

    private

    attr_reader :scope
  end
end

