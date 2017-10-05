module ApplicationHelper
  def icon(name, interactive: false)
    octicon name,
            height: 28,
            class: interactive ? 'interactive-icon' : 'icon'
  end

  # Map function with given name over enumerable collection of objects, then
  # turn result into JSON; useful when want to transform collection before
  # turning into JSON.
  def json_map(enumerable, to_json_function)
    enumerable.map(&to_json_function).to_json
  end
end
