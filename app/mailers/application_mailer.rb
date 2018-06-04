require_dependency 'alces/mailer/resender'
require_dependency 'alces/action_view/templates'

class ApplicationMailer < ActionMailer::Base
  include Resque::Mailer
  include Roadie::Rails::Automatic
  extend Alces::Mailer::Resender

  default from: "#{Rails.application.config.email_from}"
  layout 'mailer'
  helper 'mailer'
  helper 'application'

  # Need to clear the Draper view context after each mailer action, as when an
  # email is rendered this changes the view context from what we otherwise
  # expect; this was sometimes causing accessing view helper methods in
  # decorators via `h`, which should normally be available, to sometimes fail
  # due to Draper getting confused and not making the correct helpers
  # available. Doing this after we render each email appears to prevent this.
  #
  # Related discussion:
  # https://alces.slack.com/archives/C72GT476Y/p1523613894000429; somewhat
  # related issue: https://github.com/drapergem/draper/issues/814.
  after_action { Draper::ViewContext.clear! }
end
