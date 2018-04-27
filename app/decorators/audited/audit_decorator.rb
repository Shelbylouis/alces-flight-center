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

    def change_card(date, user, change)
      field = change[0]
      from, to = *change[1]

      type = send("#{field}_type")
      text = send("#{field}_text", from, to)

      render_card(date, user&.name || 'Flight Center', type, text)
    end

    def render_card(date, name, type, text)
      h.render 'cases/event', date: date, name: name, type: type, text: text
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
  end
end
