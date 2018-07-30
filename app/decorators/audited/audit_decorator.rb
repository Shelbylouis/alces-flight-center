module Audited
  class AuditDecorator < ApplicationDecorator
    def event_card
      # Make some assertions about the sort of thing we're being used to display.
      # In both cases, we could easily make this decorator flexible enough to cope
      # with a wider variety of things, but this isn't needed yet. Having these
      # exceptions here means that we'll know if we try and invalidate some of the
      # assumptions made in our implementation.
      raise "Unsupported auditable class: #{object.auditable_type}" unless object.auditable_type == 'Case'
      raise "Unsupported audit action: #{object.action}" unless object.action == 'update'

      h.raw(object.audited_changes.map { |c| change_card(object.created_at, object.user, c) }.join(''))
    end

    private

    ADMIN_ONLY_CARDS = %w(time_worked)

    def change_card(date, user, change)
      p change
      field = change[0]
      from, to = *change[1]

      type = send("#{field}_type")
      text = send("#{field}_text", from, to)
      details = send("#{field}_details")
      admin_only = ADMIN_ONLY_CARDS.include?(field)

      if text
        render_card(date, user&.name || 'Flight Center', type, text, details, admin_only)
      end
    end

    def render_card(date, name, type, text, details, admin_only)
      h.render 'cases/event',
               admin_only: admin_only,
               date: date,
               name: name,
               text: text,
               type: type,
               details: details
    end

    def assignee_id_text(from, to)
      if from
        if to
          "Changed the assignee of this case from #{User.find(from).name} to #{User.find(to).name}."
        else
          "Unassigned this case from #{User.find(from).name}."
        end
      else
        "Assigned this case to #{User.find(to).name}."
      end
    end

    def assignee_id_type
      'user'
    end

    def assignee_id_details
      'Assignee Change'
    end

    def time_worked_text(from, to)
      "Changed time worked from #{format_minutes(from)} to #{format_minutes(to)}."
    end

    def time_worked_type
      'hourglass-half'
    end

    def time_worked_details
      'Time Added'
    end

    def format_minutes(mins)
      hours, minutes = mins.divmod(60)
      if hours > 0
        "#{hours}h #{minutes}m"
      else
        "#{minutes}m"
      end
    end

    def tier_level_text(from, to)
      if to >= 3 && from <= 3
        "Escalated this case to tier #{h.tier_description(to)}."
      elsif from.nil?  # Hide initial transitions caused by data migration
        nil
      else
        raise "Unsupported tier level transition #{from} => #{to}"
      end
    end

    def tier_level_type
      'chevron-circle-up'
    end

    def tier_level_details
      'Tier Change'
    end

    def subject_text(from, to)
      "Changed the subject of this case from '#{from}' to '#{to}'."
    end

    def subject_type
      'pencil-square-o'
    end

    def subject_details
      'Subject Change'
    end
  end
end
