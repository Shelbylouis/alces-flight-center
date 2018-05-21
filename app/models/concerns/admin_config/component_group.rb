
module AdminConfig::ComponentGroup
  extend ActiveSupport::Concern

  included do
    rails_admin do
      object_label_method do
        :namespaced_name
      end

      list do
        configure :genders_host_range do
          hide
        end
      end

      edit do
        configure :genders_host_range do
          help <<-HTML.html_safe
            <p>
              Specify a genders host range to have the corresponding components
              be generated if they do not already exist, e.g. entering
              `node[01-03]` will cause components with names `node01`,
              `node02`, and `node03` to be generated.
            </p>
            <p>
              Note that this is just a convenience to allow easily creating new
              components, and existing components which either do or do not
              match will not be modified or removed.
            </p>
            <p>
              See <a
              href="https://github.com/chaos/genders/blob/390f9eb83dcc2cd7d6ee6516aa9e7b273ee80d7f/TUTORIAL#L72,L87">here</a>
              for more details of the available host range syntax.
            </p>
          HTML
        end

        configure :components do
          hide
        end
        configure :asset_record_fields do
          hide
        end
        configure :component_type do
          hide
        end
        configure :site do
          hide
        end
      end
    end
  end
end
