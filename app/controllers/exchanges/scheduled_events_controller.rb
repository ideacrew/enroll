class Exchanges::ScheduledEventsController < ApplicationController
layout 'single_column'
 
  def new
  	@scheduled_event = ScheduledEvent.new
  end

  def create
    params.permit!
    @scheduled_event = ScheduledEvent.new(scheduled_event_params)
    if @scheduled_event.save
      @scheduled_event.update_attributes!(one_time: true) if @scheduled_event.recurring_rules.present?
      redirect_to exchanges_scheduled_events_path
    end
  end

  def edit
    @scheduled_event = ScheduledEvent.find(params[:id])
  end

  def show
    @scheduled_event = ScheduledEvent.find(params[:id])
    begin
      @time = Time.parse(params[:time])
    rescue
      @time = @scheduled_event.start_time
    end
  end

  def update
    params.permit!
    @scheduled_event = ScheduledEvent.find(params[:id])
    if @scheduled_event.update_attributes!(scheduled_event_params)
      if @scheduled_event.recurring_rules.present?
        @scheduled_event.update_attributes!(one_time: true)
      else
        @scheduled_event.update_attributes!(one_time: false)
      end
      redirect_to exchanges_scheduled_events_path
    end
  end

  def index
    @scheduled_events = ScheduledEvent.all
    @calendar_events = @scheduled_events.flat_map{ |e| e.calendar_events(params.fetch(:start_date, Time.zone.now).to_date) }
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

  def scheduled_event_params
    params.require(:scheduled_event).permit(:type, :event_name, :start_time, :recurring_rules, :one_time, :offset_rule)
  end
end