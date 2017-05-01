class Exchanges::ScheduledEventsController < ApplicationController
layout 'single_column'
 
  def new
  	@scheduled_event = ScheduledEvent.new
  end

  def create
    params.permit!
    @scheduled_event = ScheduledEvent.new(params[:scheduled_event])
    if @scheduled_event.save
      @scheduled_event.update_attributes!(one_time: true) if @scheduled_event.recurring_rules.present?
      redirect_to exchanges_scheduled_events_path
    end
  end

  def edit
    @scheduled_event = ScheduledEvent.find(params[:id])
  end

  def index
    @scheduled_events = ScheduledEvent.all
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