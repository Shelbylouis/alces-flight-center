module TabsHelper
  class TabsBuilder
    def initialize(scope, h)
      @scope = scope
      @h = h
    end

    def overview
      { id: :overview, path: scope_path }
    end

    def cases
      {
        id: :cases, path: scope_path('cases'),
        dropdown: [
          { text: 'Current', path: scope_path('cases') },
          { text: 'Archive', path: scope_path('cases', archive: true) }
        ]
      }
    end

    def asset_record
      { id: :asset_record, path: scope_path('asset_record') }
    end

    private

    attr_reader :scope, :h

    def scope_path(method = nil, **hash_params)
      method_string = [
        scope.class.name.underscore, method, 'path'
      ].reject(&:nil?).join('_')
      h.send(method_string, scope, **hash_params)
    end
  end
end

