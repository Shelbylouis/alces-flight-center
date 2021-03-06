DateTimeSelect = Struct.new(:model, :datetime_field_name) do
  include ActionView::Helpers

  def select(select_name)
    parts = select_parts(select_name)
    raw(parts.join)
  end

  def id(select_name)
    "#{datetime_field_name.dasherize}-datetime-select-#{select_name}"
  end

  def label
    datetime_field_name.humanize
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

  def datetime
    model.send(datetime_field_name)
  end

  def select_options(select_name)
    {
      prefix: model.underscored_model_name,
      field_name: field_name(select_name)
    }
  end

  def select_html_options(select_name)
    {
      class: "form-control #{valid_class}",
      title: "Select #{select_name}",
      id: id(select_name)
    }
  end

  def valid_class
    model.bootstrap_valid_class(datetime_field_name)
  end

  def field_name(select_name)
    "#{datetime_field_name}(#{fragment_name(select_name)})"
  end

  def fragment_name(select_name)
    # We have to include a particular fragment in the param name for each
    # select so that ActiveRecord automatically maps these to the correct
    # DateTime instance for us. See
    # http://guides.rubyonrails.org/form_helpers.html#using-date-and-time-form-helpers-model-object-helpers.
    DATETIME_FRAGMENTS[select_name.to_sym]
  end
end
