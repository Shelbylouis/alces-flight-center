module ApplicationHelper
  def icon(name, interactive: false, inline: false, **args)
    classes = [
      (inline ? 'inline-icon' : 'fa-2x'),
      (interactive ? 'interactive-icon' : 'icon'),
      args.delete(:class)
    ].join(' ')

    fa_icon name, class: classes, **args
  end

  def boolean_symbol(condition)
    raw(condition ? '&check;' : '&cross;')
  end

  def new_case_form(clusters:, single_part: nil)
    clusters_json = json_map(clusters, :case_form_json)
    raw(
      <<~EOF
        <div
          id='new-case-form'
          data-clusters='#{clusters_json}'
          #{single_part_data_attr(single_part)}
        ></div>
      EOF
    )
  end

  def scope_nav_link_procs
    return @scope_nav_link_procs if @scope_nav_link_procs
    @scope_nav_link_procs ||= []

    if current_user&.admin?
      @scope_nav_link_procs << nav_link_proc(text: 'All Sites',
                                      path: root_path,
                                      nav_icon: 'fa-globe')
    end

    if @scope
      site_obj = model_from_scope :site
      path_for_site = if current_user.admin?
                        site_obj
                      else
                        root_path
                      end
      @scope_nav_link_procs << nav_link_proc(model: site_obj,
                                      path: path_for_site,
                                      nav_icon: 'fa-institution')

      cluster_obj = model_from_scope :cluster
      if cluster_obj
        @scope_nav_link_procs << nav_link_proc(model: cluster_obj,
                                        nav_icon: 'fa-server')
      end

      component_group_obj = model_from_scope :component_group
      if component_group_obj
        @scope_nav_link_procs << nav_link_proc(model: component_group_obj,
                                        nav_icon: 'fa-cubes')
      end

      if @cluster_part
        @scope_nav_link_procs << nav_link_proc(model: @cluster_part,
                                        nav_icon: 'fa-cube')
      end
    end

    @scope_nav_link_procs
  end

  def icon_span(text, icon = '')
    raw("<span class='fa #{icon}'></span> ") + text
  end

  def dark_button_classes
    ['btn', 'btn-primary', 'btn-block']
  end

  private

  # Map function with given name over enumerable collection of objects, then
  # turn result into JSON; useful when want to transform collection before
  # turning into JSON.
  def json_map(enumerable, to_json_function)
    enumerable.map(&to_json_function).reject(&:nil?).to_json
  end


  def single_part_data_attr(single_part)
    return unless single_part

    single_part_json ={
      id: @single_part.id,
      type: @single_part.class.to_s.downcase
    }.to_json

    "data-single-part=#{single_part_json}"
  end

  def model_from_scope(type)
    if @scope.respond_to? type
      @scope.public_send type
    elsif @scope.is_a?(type.to_s.classify.constantize)
      @scope
    else
      nil
    end
  end

  def nav_link_proc(**inputs_to_partial)
    Proc.new do |**additional_inputs|
      render 'partials/nav_link', **additional_inputs, **inputs_to_partial
    end
  end
end
