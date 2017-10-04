module ApplicationHelper
  def icon(name, interactive: false)
    octicon name,
            height: 28,
            class: interactive ? 'interactive-icon' : 'icon'
  end
end
