class CollatedCaseAssociationAuditDecorator < ApplicationDecorator
  def event_card
    h.render 'cases/event',
             name: object.user&.name || 'Flight Center',
             date: object.created_at,
             text: card_text,
             formatted: false,
             type: 'link',
             details: 'Affected component change'
  end

  private

  def card_text
    [additions_text, deletions_text]
      .compact
      .tap { |texts|
        if texts.count == 1
          texts[0].chomp!(',')
        end
        texts[0][0] = texts[0][0].upcase
      }
      .join(' and ') +
      ' the list of affected components.'
  end

  def additions_text
    "added #{item_list(object.additions)} to," unless object.additions.empty?
  end

  def deletions_text
    "deleted #{item_list(object.deletions)} from," unless object.deletions.empty?
  end

  def item_list(items)
    entries = items.map { |i|
      item_list_entry(i)
    }

    if entries.count > 2
      last_entry = entries.pop
      first_entries = entries.empty? ? nil : entries.join(', ')

      [first_entries, last_entry].compact.join(', and ')
    else
      entries.join(' and ')
    end

  end

  def item_list_entry(item)
    i = item.decorate
    "<i class=\"fa #{i.fa_icon}\" title=\"#{i.type_name}\"></i> " +
      h.link_to(i.name, i.path)
  end
end
