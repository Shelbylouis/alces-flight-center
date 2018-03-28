module TabsHelper
  class TabsBuilder
    def initialize(scope, h)
      @scope = scope.decorate
      @h = h
    end

    def overview
      { id: :overview, path: scope.scope_path }
    end

    def cases
      {
        id: :cases, path: scope.scope_cases_path,
        dropdown: [
          { text: 'Current', path: scope.scope_cases_path },
          { text: 'Archive', path: scope.scope_cases_path(archive: true) }
        ]
      }
    end

    def asset_record
      { id: :asset_record, path: scope.scope_asset_record_path }
    end

    private

    attr_reader :scope, :h
  end
end

