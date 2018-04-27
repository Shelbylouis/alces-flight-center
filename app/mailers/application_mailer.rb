require_dependency 'alces/mailer/resender'
require_dependency 'alces/action_view/templates'

class ApplicationMailer < ActionMailer::Base
  include Roadie::Rails::Automatic
  extend Alces::Mailer::Resender

  default from: 'center@alces-flight.com'
  layout 'mailer'
  helper 'mailer'
end
