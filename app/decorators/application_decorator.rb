
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

  def method_missing(s, *a, **hash, &b)
    if respond_to_missing?(s, *a) == :scope_path
      h.send(convert_scope_path(s), *arguments_for_scope_path(a), **hash, &b)
    else
      super
    end
  end

  def respond_to_missing?(s, *_a)
    s.match?(/\A(.+_)?scope_(.+_)?path\Z/) ? :scope_path : super
  end

  private

  def convert_scope_path(s)
    name_for_path = scope_name_for_paths.dup.tap do |name|
      name << '_' if name.present?
    end
    s.to_s
     .sub(/((.+_)?)scope_/, '\1' + name_for_path)
     .sub(/\Apath\Z/, 'root_path')
     .to_sym
  end

  # Override this method for non-standard scope names/ paths
  def scope_name_for_paths
    model.underscored_model_name
  end

  # Override this method for non-standard scope names/ paths
  def arguments_for_scope_path(*a)
    a.unshift(model)
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

    title = "#{title_base} for case #{window.case.display_id}"

    h.icon('wrench', inline: true, class: class_names, title: title)
  end

  def new_maintenance_window_path
    link_helper = "new_#{underscored_model_name}_maintenance_window_path"
    h.send(link_helper, self)
  end

  def id_key
    "#{underscored_model_name}_id".to_sym
  end

  def tabs_builder
    @tabs_builder ||= TabsBuilder.new(object)
  end
end
