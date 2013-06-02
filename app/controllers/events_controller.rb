class EventsController < ApplicationController

  def view
    Rails.logger.info(params)

    @event = Event.find_by_event_code(params["id"])
    render 'events/show'
  end

  def all
    @events = Event.all
    render 'events/all'
  end


end
