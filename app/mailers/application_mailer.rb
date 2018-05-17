require_dependency 'alces/mailer/resender'
require_dependency 'alces/action_view/templates'

class ApplicationMailer < ActionMailer::Base
  include Resque::Mailer
  include Roadie::Rails::Automatic
  extend Alces::Mailer::Resender

  default from: "#{Rails.application.config.email_app_name} <center@alces-flight.com>"
  layout 'mailer'
  helper 'mailer'
  helper 'application'
end
