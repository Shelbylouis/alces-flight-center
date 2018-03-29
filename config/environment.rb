# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Remove default `field_with_errors` wrapper Rails puts around form
# helper-generated inputs for fields with errors (see
# https://coderwall.com/p/s-zwrg/remove-rails-field_with_errors-wrapper).
ActionView::Base.field_error_proc = Proc.new do |html_tag, _instance|
  html_tag.html_safe
end
