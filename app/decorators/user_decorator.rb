class UserDecorator < ApplicationDecorator
  def info
    "#{model.name} (<a href=\"mailto:#{model.email}\">#{model.email}</a>)".html_safe
  end
end
