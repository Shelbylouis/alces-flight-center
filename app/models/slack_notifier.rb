require 'slack-notifier'
class SlackNotifier

  attr_accessor :notifier

  def initialize
    @notifier = Slack::Notifier.new "https://hooks.slack.com/services/" \
    "T025J03QZ/BAV4MH1SM/pKlzYfY1efTsl0bFWGtKg8bQ"
  end

  def case
  end

  def assignee

  end

  def comment
  end

  def maintenance
  end

  def log
  end
end
