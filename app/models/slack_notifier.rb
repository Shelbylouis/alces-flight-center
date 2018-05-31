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
      color: "#18bc9c",
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
      ]
    }

    notifier.ping attachments: case_note
  end

  def assignee_notification(kase)
    notification_text = "#{kase.assignee.name} has been assigned to #{kase.display_id}"
    assignee_note = {
      fallback: notification_text,
      color: "#6e5494",
      pretext: notification_text,
      title: kase.subject,
      title_link: Rails.application.routes.url_helpers.cluster_case_url(kase.cluster, kase),
      fields: [
        {
          title: "ID",
          value: kase.display_id,
          short: true
        },
        {
          title: "Assigned to",
          value: kase.assignee.name,
          short: true
        }
      ]
    }

    notifier.ping attachments: assignee_note
  end

  def comment_notification(kase, comment)
    notification_text = "New comment from #{comment.user.name} on #{kase.display_id}"
    comment_note = {
      fallback: notification_text,
      color: "#2794d8",
      pretext: notification_text,
      author_name: comment.user.name,
      title: kase.subject,
      title_link: Rails.application.routes.url_helpers.cluster_case_url(kase.cluster, kase),
      text: comment.text
    }

    notifier.ping attachments: comment_note
  end

  def maintenance_notification(kase, text)
    maintenance_note = {
      fallback: text,
      color: "#000000",
      title: "#{kase.subject} (#{kase.display_id})",
      title_link: Rails.application.routes.url_helpers.cluster_case_url(kase.cluster, kase),
      fields: [
        {
          title: "Maintenance Info",
          value: text,
          short: false
        }
      ]
    }

    notifier.ping attachments: maintenance_note
  end

  def log_notification(log)
    notification_text = "New log created by #{log.engineer.name} on " \
      "#{log.cluster.name} #{log&.component ? 'for ' + log.component.name : nil }"
    log_note = {
      fallback: notification_text,
      color: "#8daec2",
      pretext: notification_text,
      fields: [
        {
          title: "Details",
          value: log.details,
          short: false
        }
      ],
      footer: "<#{Rails.application.routes.url_helpers.cluster_logs_url(log.cluster)}|#{log.cluster.name} Logs>"
    }

    notifier.ping attachments: log_note
  end
end
