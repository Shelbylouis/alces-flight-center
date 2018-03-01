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

  def model_from_scope(type)
    if @scope.respond_to? type
      @scope.public_send type
    elsif @scope.is_a?(type.to_s.classify.constantize)
      @scope
    else
      nil
    end
  end

  def add_nav_link_proc(**inputs_to_partial)
    nav_link_procs << Proc.new do |**additional_inputs|
      render 'partials/nav_link', **additional_inputs, **inputs_to_partial
    end
  end

  def nav_link_procs
    @nav_link_procs ||= []
  end

  def render_tab_bar(**render_args, &b)
    if @scope.is_a? Cluster
      render('clusters/tabs', **render_args, &b)
    end
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
end
