class Exchanges::ScheduledEventsController < ApplicationController
  layout "single_column"

  before_action :scheduled_event_params, only: [:create, :update]
  before_action :redirect_if_calendar_tab_is_disabled

  def new
    @scheduled_event = ScheduledEvent.new
  end

  def list
  end

  def create
    scheduled_event = ScheduledEvent.new(scheduled_event_params)
    if scheduled_event.save!
      scheduled_event.update_attributes!(one_time: false) if scheduled_event.recurring_rules.present?
      @flash_message = 'Event successfully created'
      @flash_type = 'success'
      @calendar_events = load_calendar_events
    else
      @flash_message = scheduled_event.errors.values.flatten.to_sentence
      @flash_type = 'error'
      @scheduled_event = scheduled_event
      render :new
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
    if scheduled_event.update_attributes!(scheduled_event_params)
      scheduled_event.event_exceptions.delete_all
      if scheduled_event.recurring_rules.present?
        scheduled_event.update_attributes!(one_time: false)
      else
        scheduled_event.update_attributes!(one_time: true)
      end
      @scheduled_event = scheduled_event
      @flash_message = "Event successfully updated"
      @flash_type = 'success'
      render :list
    else
      @flash_message = scheduled_event.errors.values.flatten.to_sentence
      @flash_type = 'error'
      @scheduled_event = scheduled_event
      render :edit
    end
  end

  def index
    @calendar_events = load_calendar_events
    respond_to do |format|
      format.html { render "exchanges/scheduled_events/index.html.erb" }
    end
  end

  def destroy
    if scheduled_event.destroy
      @flash_message = 'Current Event was successfully destroyed.'
      @flash_type = 'success'
    else
      @flash_message = "We encountered an error trying to remove this occurence"
      @flash_type = 'alert'
    end
    @calendar_events = load_calendar_events
  end

  def current_events
    if params[:event] == 'system'
      @events = ScheduledEvent::SYSTEM_EVENTS
    end
    render partial: 'exchanges/scheduled_events/get_events_field', locals: { event: params[:event] }

  end

  def delete_current_event
    if scheduled_event.event_exceptions.create!(time: params[:time])
      @flash_message = "#{scheduled_event.event_name.humanize} on #{params[:time]} was successfully removed"
      @flash_type = 'success'
    else
      @flash_message = "We encountered an error trying to remove this occurence"
      @flash_type = 'alert'
    end
    @calendar_events = load_calendar_events
  end

  private

    helper_method :scheduled_event, :scheduled_events

  def redirect_if_calendar_tab_is_disabled
    redirect_to(main_app.root_path, notice: l10n("calendar_not_enabled")) unless EnrollRegistry.feature_enabled?(:calendar_tab)
  end

    def load_calendar_events
      scheduled_events.flat_map do |e|
        if params.key?("start_date")
          e.calendar_events(Date.strptime(params.fetch(:start_date, TimeKeeper.date_of_record ), "%m/%d/%Y").to_date, e.offset_rule)
        else
          e.calendar_events((params.fetch(:start_date, TimeKeeper.date_of_record)).to_date, e.offset_rule)
        end
      end
    end

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
