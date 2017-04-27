class Exchanges::ScheduledEventsController < ApplicationController
 
  def new
  	@scheduled_event = ScheduledEvent.new
  	respond_to do |format|
      format.js { render 'new' }
    end
  end

  def get_system_events
  	@events = ScheduledEvent::SYSTEMS_EVENTS
    if @events.present?
      render partial: 'exchanges/scheduled_events/get_events_field'
    else
      render nothing: true
    end
  end

  def get_holiday_events
  	@events = ScheduledEvent::HOLIDAYS
    if @events.present?
      render partial: 'exchanges/scheduled_events/get_events_field'
    else
      render nothing: true
    end
  end

  def no_events
  	@events = []
  	render partial: 'exchanges/scheduled_events/get_events_field'
  end
end