require 'rails_helper'

RSpec.describe Exchanges::ScheduledEventsController do

  let(:user){ double(:save => double("user")) }
  let(:person) { FactoryGirl.create(:person) }  
  let(:event_params) { {
      type: 'holiday',
      event_name: 'Christmas',
      offset_rule: 3,
      recurring_rules: {},
      :start_time => Date.today
    }}
  before do
    sign_in(user)
  end
  
  describe "GET new" do
	it "should render the new template" do
	  get :new
      expect(response).to have_http_status(:success)
    end
  end

  describe "Create Post" do
    let(:scheduled_event) { ScheduledEvent.new(event_params) }
  	
  	it "returns http status" do
  	  scheduled_event.stub(:save).and_return true
      post :create, scheduled_event: event_params
      expect(response).to redirect_to exchanges_scheduled_events_path
    end
    it "should render new template when invalid params" do
      scheduled_event.stub(:save).and_return false
      post :create, scheduled_event: event_params
      expect(response).to redirect_to exchanges_scheduled_events_path
    end
  end

  describe "destroy" do
    let(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
    before :each do
      delete :destroy, id: scheduled_event.id
    end
    it "redirects_to index page" do
      expect(response).to redirect_to exchanges_scheduled_events_path
    end
  end

  describe "update" do
    context "remove event exceptions"
      let!(:event_exception) { FactoryGirl.create(:event_exception) }
      it "delete event exceptions" do
        put :update, scheduled_event: event_params
        expect(ScheduledEvent.all.first.event_exceptions.length).to eq 0
      end
    end
  end

  describe "GET index" do
    let(:scheduled_event) { FactoryGirl.create(:scheduled_event) }
    let(:scheduled_events) { [scheduled_event] }
    it 'assigns scheduled_events' do
      get :index, scheduled_event: event_params
      assigns[:scheduled_events].should_not be_nil
    end
  end

  describe "GET#get_system_events" do    
    before do
      get :get_system_events
    end

    it "should return supported events" do
      expect(response).to render_template(:'exchanges/scheduled_events/_get_events_field')
      expect(assigns(:events)).to match_array(%W(Binder_Payment_due_Date Publish_Due_Date_Of_Month monthly_enrollment_due_on
                                                 initial_application_publish_due_day_of_month renewal_application_monthly_open_enrollment_end_on
                                                 renewal_application_publish_due_day_of_month renewal_application_force_publish_day_of_month
                                                 open_enrollment_monthly_end_on group_file_new_enrollment_transmit_on
                                                 group_file_update_transmit_day_of_week))
    end
  end

  describe "GET#get_holiday_events" do
    before do
      get :get_holiday_events
    end

    it "should return supported events" do
      expect(response).to render_template(:'exchanges/scheduled_events/_get_events_field')
      expect(assigns(:events)).to match_array(%W(New_Year MartinLuthor_birthdday washingtons_day memorial_day independence_day
                                                 Labour_day columbus_day veterans_day Christmas Thanksgiving_day))
    end
  end
end