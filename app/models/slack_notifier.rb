require 'slack-notifier'
class SlackNotifier
  class << self
    delegate :slack_webhook_url,
      :slack_channel,
      :slack_username,
      to: 'Rails.application.config'

    def case_notification(kase)
      notification_text = "New case created on #{kase.cluster.name}"

      case_url = url_helpers('cluster_case_url', kase.cluster, kase)

      kase.fields.each do |field|
        (@notification_details ||= "*Tier #{kase.tier_level}*") << "\n*#{field["name"]}*"\
          "\n#{restrict_text_length(field["value"], case_url)}"
      end unless kase.fields.nil?

      case_note = {
        fallback: notification_text,
        color: "#18bc9c",
        pretext: notification_text,
        author_name: kase.user.name,
        title: subject_and_id_title(kase),
        title_link: case_url,
        text: @notification_details,
        mrkdwn: true,
        footer: "<#{url_helpers('cluster_cases_url', kase.cluster)}|#{kase.cluster.name} Cases>"
      }

      send(case_note)
    end

    def assignee_notification(kase, assignee)
      notification_text = "#{assignee.name} has been assigned to #{kase.display_id}"

      assignee_note = {
        fallback: notification_text,
        color: "#6e5494",
        title: subject_and_id_title(kase),
        title_link: url_helpers('cluster_case_url', kase.cluster, kase),
        fields: [
          {
            title: "Assigned to",
            value: assignee.name,
            short: true
          }
        ]
      }

      send(assignee_note)
    end

    def comment_notification(kase, comment)
      notification_text = "New comment from #{comment.user.name} on #{kase.display_id}"
      comment_note = {
        fallback: notification_text,
        color: "#2794d8",
        author_name: comment.user.name,
        title: subject_and_id_title(kase),
        title_link: url_helpers('cluster_case_url', kase.cluster, kase),
        fields: [
          {
            title: "New comment",
            value: comment.text,
            short: false
          }
        ]
      }

      send(comment_note)
    end

    def maintenance_notification(kase, text)
      maintenance_note = {
        fallback: text,
        color: "#000000",
        title: subject_and_id_title(kase),
        title_link: url_helpers('cluster_case_url', kase.cluster, kase),
        fields: [
          {
            title: "Maintenance Info",
            value: text,
            short: false
          }
        ],
        footer: "<#{url_helpers('cluster_maintenance_windows_url', kase.cluster)}|#{kase.cluster.name} Maintenance>"
      }

      send(maintenance_note)
    end

    def log_notification(log)
      notification_text = "New log created by #{log.engineer.name} on " \
        "#{log.cluster.name} #{log&.component ? 'for ' + log.component.name : nil }"

      logs_url = url_helpers('cluster_logs_url', log.cluster)

      log_note = {
        fallback: notification_text,
        color: "#8daec2",
        pretext: notification_text,
        title: "Details",
        title_link: logs_url,
        text: restrict_text_length(log.details, logs_url),
        mrkdwn: true,
        footer: "<#{logs_url}|#{log.cluster.name} Logs>"
      }

      send(log_note)
    end

    private

    def notifier
      Slack::Notifier.new slack_webhook_url
    end

    def send(note)
      return unless slack_webhook_url
      notifier.ping channel: slack_channel,
        username: slack_username,
        attachments: note
    end

    def restrict_text_length(text, url)
      text.length > 80 ? text[0, 80] + "<#{url}|...>" : text
    end

    def subject_and_id_title(kase)
      "#{kase.subject} - #{kase.display_id}"
    end

    def url_helpers(helper, *args)
      Rails.application.routes.url_helpers.public_send(helper, *args)
    end
  end
end
