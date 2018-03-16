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
          { text: 'Archive', path: scope_path('cases') }
        ]
      }
    end

    def asset_record
      { id: :asset_record, path: scope_path('asset_record') }
    end

    private

    attr_reader :scope, :h

    def scope_path(method = nil)
      method_string = scope.class.name.underscore.tap do |str|
        str << "_#{method}" unless method.blank?
        str << '_path'
      end
      h.send(method_string, scope)
    end
  end
end

