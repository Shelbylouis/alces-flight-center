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
      field = change[0]
      from, to = *change[1]

      type = send("#{field}_type")
      text = send("#{field}_text", from, to)
      admin_only = ADMIN_ONLY_CARDS.include?(field)

      render_card(date, user&.name || 'Flight Center', type, text, admin_only)
    end

    def render_card(date, name, type, text, admin_only)
      h.render 'cases/event',
               admin_only: admin_only,
               date: date,
               name: name,
               text: text,
               type: type
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

    def time_worked_text(from, to)
      "Changed time worked from #{format_minutes(from)} to #{format_minutes(to)}."
    end

    def time_worked_type
      'hourglass-half'
    end

    def format_minutes(mins)
      hours, minutes = mins.divmod(60)
      if hours > 0
        "#{hours}h #{minutes}m"
      else
        "#{minutes}m"
      end
    end

    def credit_charge_text(from, to)
      if from.nil?
        "A charge of #{h.pluralize(to, 'credit')} was added for this case."
      else
        "The credit charge attached to this case was changed from #{from} to #{pluralize(to, 'credit')}"
      end
    end

    def credit_charge_type
      'usd'
    end

    def tier_level_text(from, to)
      if to == 3 && from < 3
        'Escalated this case to tier 3 (General support)'
      else
        raise "Unsupported tier level transition #{from} => #{to}"
      end
    end

    def tier_level_type
      'chevron-circle-up'
    end
  end
end
