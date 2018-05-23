class LogDecorator < ApplicationDecorator
  def event_card
    h.render 'cases/event',
             name: object.engineer.name,
             date: object.created_at,
             text: object.details,
             type: 'pencil-square-o'
  end
end
