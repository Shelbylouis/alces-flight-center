
# XXX Nothing in here is applicable to every decorated model in the app, it's
# just a bit of a dumping ground. At some point should pull things out to
# better places.
class ApplicationDecorator < Draper::Decorator
  # Define methods for all decorated objects.
  # Helpers are accessed through `helpers` (aka `h`). For example:
  #
  #   def percent_amount
  #     h.number_to_percentage object.amount, precision: 2
  #   end

  def start_maintenance_request_link
    return unless h.current_user.admin?

    title = "Start request for maintenance of this #{readable_model_name}"
    h.link_to(
      h.raw(h.icon 'wrench', interactive: true),
      new_maintenance_window_path,
      title: title
    )
  end

  # Strictly speaking this gives the icons for a ClusterPart or entire Cluster,
  # but I don't have a better name for that yet.
  def cluster_part_icons
    icons = [internal_icon, *maintenance_icons]
    h.raw(icons.join)
  end

  # As above: strictly speaking this gives the buttons for a ClusterPart or
  # entire Cluster, but I don't have a better name for that yet.
  def cluster_part_case_form_buttons
    buttons = [
      case_form_button(case_form_path, disabled: advice?),
      consultancy_form_button(consultancy_form_path)
    ].join
    h.raw(buttons)
  end

  # Override this method to generate the tab bars
  def tabs
    []
  end

  def bootstrap_valid_class(field_name)
    errors[field_name].any? ? 'is-invalid' : 'is-valid'
  end

  def invalid_feedback_div(field_name)
    h.raw(
      [
        '<div class="invalid-feedback">',
        errors[field_name].join('; ').capitalize,
        '</div>',
      ].join
    )
  end

  def method_missing(s, *a, &b)
    if respond_to_missing?(s, *a) == :scope_path
      h.send(convert_scope_path(s), model, *a, &b)
    else
      super
    end
  end

  def respond_to_missing?(s, *_a)
    s.match?(/\A(.+_)?scope_(.+_)?path\Z/) ? :scope_path : super
  end

  private

  def convert_scope_path(s)
    (s.match(/\Ascope_.*/) ? "_#{s}" : s.to_s)
      .sub(/_scope_/, scope_name_for_paths)
      .sub(/\A_/, '')
      .sub(/\Apath\Z/, 'root_path')
      .to_sym
  end

  # This method is overridden in the Site decorator
  def scope_name_for_paths
    '_' + model.underscored_model_name + '_'
  end

  def internal_icon
    internal_text = "#{readable_model_name.capitalize} for internal Alces usage"
    if respond_to?(:internal) && internal
      h.image_tag(
        'flight-icon',
        alt: internal_text,
        title: internal_text,
      )
    end
  end

  def maintenance_icons
    maintenance_windows.map { |window| maintenance_icon(window) }
  end

  def maintenance_icon(window)
    case window.state.to_sym
    when :requested
      class_names = 'faded-icon'
      title_base = "Maintenance has been requested for #{name}"
    when :confirmed
      class_names = 'faded-icon'
      title_base = "Maintenance is scheduled for #{name}"
    when :started
      class_names = nil
      title_base = "#{name} currently under maintenance"
    else
      return
    end

    title = "#{title_base} for ticket #{window.case.rt_ticket_id}"

    h.icon('wrench', inline: true, class: class_names, title: title)
  end

  def new_maintenance_window_path
    link_helper = "new_#{readable_model_name}_maintenance_window_path"
    h.send(link_helper, self)
  end

  def case_form_path
    helper = "new_#{readable_model_name}_case_path"
    h.send(helper, id_key => self.id)
  end

  def consultancy_form_path
    helper = "new_#{readable_model_name}_consultancy_path"
    h.send(helper, id_key => self.id)
  end

  def id_key
    "#{readable_model_name}_id".to_sym
  end

  def case_form_button(path, disabled: false)
    title = <<~EOF.squish if disabled
      This #{readable_model_name} is self-managed; if required you
      may only request consultancy support from Alces Software.
    EOF

    card_header_button_link 'Create new support case',
      path,
      buttonClass: 'btn-primary',
      disabled: disabled,
      title: title
  end

  def consultancy_form_button(path)
    card_header_button_link 'Request consultancy',
      path,
      buttonClass: 'btn-danger'
  end

  def card_header_button_link(text, path, buttonClass:, disabled: false, title: nil)
    link = h.link_to text,
      path,
      class: ['nav-link', 'btn', buttonClass, disabled ? 'disabled' : nil],
      role: 'button',
      title: title

    h.raw("<li class=\"nav-item\" title=\"#{title}\">#{link}</li>")
  end

  def tabs_builder
    @tabs_builder ||= TabsHelper::TabsBuilder.new(object, h)
  end
end
