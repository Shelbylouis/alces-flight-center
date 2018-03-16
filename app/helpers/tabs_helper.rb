module TabsHelper
  class TabsBuilder
    def initialize(scope, h)
      @scope = scope
      @h = h
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

    private

    attr_reader :scope, :h

    def scope_path(method)
      method_string = "#{scope.class.to_s.downcase}_#{method}_path"
      h.send(method_string, scope)
    end
  end
end

