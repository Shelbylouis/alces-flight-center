module DateTimeSelectHelper
  DateTimeSelect = Struct.new(:model, :datetime, :identifier) do
    include ActionView::Helpers

    def select(select_name)
      parts = select_parts(select_name)
      raw(parts.join)
    end

    def id(select_name)
      "#{identifier}-datetime-select-#{select_name}"
    end

    def label
      identifier.underscore.humanize
    end

    private

    DATETIME_FRAGMENTS = {
      year: '1i',
      month: '2i',
      day: '3i',
      hour: '4i',
      minute: '5i',
    }.freeze

    def select_parts(select_name)
      [
        '<div class="col-md-2">',
        select_field(select_name),
        '</div>'
      ]
    end

    def select_field(select_name)
      helper_method = "select_#{select_name}"
      send(
        helper_method,
        datetime,
        select_options(select_name),
        select_html_options(select_name)
      )
    end

    def select_options(select_name)
      {
        prefix: model,
        field_name: field_name(select_name)
      }
    end

    def select_html_options(select_name)
      {
        class: 'form-control',
        title: "Select #{select_name}",
        id: id(select_name)
      }
    end

    def field_name(select_name)
      "#{identifier.underscore}(#{fragment_name(select_name)})"
    end

    def fragment_name(select_name)
      # We have to include a particular fragment in the param name for each
      # select so that ActiveRecord automatically maps these to the correct
      # DateTime instance for us. See
      # http://guides.rubyonrails.org/form_helpers.html#using-date-and-time-form-helpers-model-object-helpers.
      DATETIME_FRAGMENTS[select_name.to_sym]
    end
  end
end
