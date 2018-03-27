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

    def page_is_a_contacts_site?
      scope.is_a?(Site) && h.current_user.contact?
    end

    # Regular contacts have their site as the root path and thus need to be
    # handled separately
    def scope_path(method = nil, **hash_params)
      method_args = begin
        if page_is_a_contacts_site?
          [(method ? method : 'root') + '_path']
        else
          method_string = [
            scope.class.name.underscore, method, 'path'
          ].reject(&:nil?).join('_')
          [method_string, scope]
        end
      end
      h.send(*method_args, **hash_params)
    end
  end
end

