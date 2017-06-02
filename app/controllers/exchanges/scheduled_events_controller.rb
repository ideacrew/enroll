class Exchanges::ScheduledEventsController < ApplicationController

  def new
  	@scheduled_event = ScheduledEvent.new
  end

  def list
  end

  def create
    params.permit!
    scheduled_event = ScheduledEvent.new(scheduled_event_params)
    if scheduled_event.save
      scheduled_event.update_attributes!(one_time: false) if scheduled_event.recurring_rules.present?
      redirect_to exchanges_scheduled_events_path
    else
      flash[:error] = scheduled_event.errors.values.flatten.to_sentence
      @scheduled_event = scheduled_event
      render action: :new
    end
  end

  def edit
  end

  def show
    begin
      @time = Date.strptime(params[:time], "%m/%d/%Y").to_date
    rescue
      @time = @scheduled_event.start_time
    end
  end

  def update
    params.permit!
    if scheduled_event.update_attributes!(scheduled_event_params)
      scheduled_event.event_exceptions.delete_all
      if scheduled_event.recurring_rules.present?
        scheduled_event.update_attributes!(one_time: false)
      else
        scheduled_event.update_attributes!(one_time: true)
      end
      redirect_to exchanges_scheduled_events_path
    end
  end

  def index
    @calendar_events = scheduled_events.flat_map do |e|
      if params.key?("start_date")
        e.calendar_events(Date.strptime(params.fetch(:start_date, TimeKeeper.date_of_record ), "%m/%d/%Y").to_date)
      else
        e.calendar_events((params.fetch(:start_date, TimeKeeper.date_of_record)).to_date)
      end
    end
  end

  def destroy
    scheduled_event.destroy
    respond_to do |format|
      format.html { redirect_to exchanges_scheduled_events_path, notice: 'Event was successfully destroyed.' }
    end
  end

  def current_events
    if params[:event] == 'system'
      @events = ScheduledEvent::SYSTEM_EVENTS
    end
    render partial: 'exchanges/scheduled_events/get_events_field', locals: { event: params[:event] }

  end

  def delete_current_event
    if @exception = scheduled_event.event_exceptions.create(time: params[:time])
      redirect_to exchanges_scheduled_events_path, notice: 'Current Event was successfully destroyed.'
    else
      flash.alert = "Unable to add exception"
      redirect_to exchanges_scheduled_events_path
    end
  end

  private

    helper_method :scheduled_event, :scheduled_events

    def scheduled_event_params
      params.require(:scheduled_event).permit(:type, :event_name, :start_time, :recurring_rules, :one_time, :offset_rule)
    end

    def scheduled_event
      @scheduled_event ||= ScheduledEvent.find(params[:id])
    end

    def scheduled_events
      @scheduled_events ||= ScheduledEvent.all
    end
end
