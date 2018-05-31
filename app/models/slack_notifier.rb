require 'slack-notifier'
class SlackNotifier

  attr_reader :notifier

  def initialize
    @notifier = Slack::Notifier.new "https://hooks.slack.com/services/" \
    "T025J03QZ/BAV4MH1SM/pKlzYfY1efTsl0bFWGtKg8bQ"
  end

  def case_notification(kase)
    notification_text = "New case created on #{kase.cluster.name}"
    case_note = {
      fallback: notification_text,
      color: "#2794d8",
      pretext: notification_text,
      author_name: kase.user.name,
      title: kase.subject,
      title_link: Rails.application.routes.url_helpers.cluster_case_url(kase.cluster, kase),
      fields: [
        {
          title: "Tier",
          value: kase.tier_level,
          short: true
        },
        {
          title: "ID",
          value: kase.display_id,
          short: true
        },
      ],
    }

    notifier.ping attachments: case_note
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
