module ApplicationHelper
  # Note: These should match values used in `Tier.Level.description` in Case
  # form app.
  TIER_DESCRIPTIONS = {
      1 => 'Tool',
      2 => 'Routine Maintenance',
      3 => 'General Support',
  }.freeze

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

  def new_case_form(clusters:, single_part: nil, pre_selected: {})
    clusters_json = json_map(clusters.map(&:decorate), :case_form_json)
    raw(
      <<~EOF
        <div
          id='new-case-form'
          data-clusters='#{clusters_json}'
          #{single_part_data_attr(single_part)}
          #{selected_data_attr(:category, pre_selected)}
          #{selected_data_attr(:issue, pre_selected)}
          #{selected_data_attr(:service, pre_selected)}
          #{selected_data_attr(:tier, pre_selected)}
          #{selected_data_attr(:tool, pre_selected)}
        ></div>
      EOF
    )
  end

  def scope_nav_link_procs
    @scope_nav_link_procs ||= ScopeNavLinksBuilder.new(scope: @scope).build
  end

  def icon_span(text, icon = '')
    raw("<span class='fa #{icon}'></span> ") + text
  end

  def dark_button_classes
    ['btn', 'btn-primary', 'btn-block']
  end

  def timestamp_td(description:, timestamp:)
    ts = timestamp.to_formatted_s(:short)
    content = block_given? ? (yield ts) : ts
    raw(
      <<~EOF.strip_heredoc
        <td
          title="#{description} on #{timestamp.to_formatted_s(:long)}"
          class="nowrap"
        >
          #{content}
        </td>
      EOF
    )
  end

  def tier_description(tier_level)
    unless TIER_DESCRIPTIONS.has_key?(tier_level)
      raise "Unhandled tier_level: #{tier_level}"
    end
    description = TIER_DESCRIPTIONS[tier_level]
    "#{tier_level} (#{description})"
  end

  def simple_format_if_needed(text)
    text.include?("\n") ? simple_format(text) : text
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

  def selected_data_attr(item_name, selected_items)
    item = selected_items.fetch(item_name, nil)
    return nil if item.nil?

    return "data-selected-#{item_name}='\"#{item}\"'"
  end
end
