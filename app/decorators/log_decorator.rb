class LogDecorator < ApplicationDecorator
  def event_card
    h.render 'cases/event',
             name: object.engineer.name,
             date: object.created_at,
             text: object.rendered_details,
             formatted: true,
             type: 'pencil-square-o',
             details: 'Log Entry'
  end
end
