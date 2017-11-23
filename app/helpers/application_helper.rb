module ApplicationHelper
  def icon(name, interactive: false, inline: false, **args)
    classes = [
      (inline ? 'inline-icon' : 'fa-2x'),
      (interactive ? 'interactive-icon' : 'icon')
    ].join(' ')

    fa_icon name, class: classes, **args
  end

  # Map function with given name over enumerable collection of objects, then
  # turn result into JSON; useful when want to transform collection before
  # turning into JSON.
  def json_map(enumerable, to_json_function)
    enumerable.map(&to_json_function).reject(&:nil?).to_json
  end
end
