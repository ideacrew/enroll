# frozen_string_literal: true

require 'rails_helper'
RSpec.describe EventLogs::MonitoredEvent, :type => :model, dbclean: :around_each do

  before(:each) do
    @user = FactoryBot.create(:user)
    @person_event_log = FactoryBot.create(:people_eligibilities_event_log, account: @user)
    @monitored_event = FactoryBot.create(:monitored_event, account_username: @user.email, monitorable: @person_event_log)
    @monitored_event_2 = FactoryBot.create(:monitored_event, event_category: :osse, subject_hbx_id: "10005", monitorable: @person_event_log)
  end

  describe "monitored event" do

    context ".save" do
      it "should persist event log" do
        expect(EventLogs::MonitoredEvent.count).to eq 2
        expect(EventLogs::MonitoredEvent.first).to eq @monitored_event
      end

      it "should find events from collection" do
        expect(
          EventLogs::MonitoredEvent.where(
            @monitored_event.attributes.slice(:account_hbx_id, :event_category)
          ).first
        ).to eq @monitored_event
      end
    end

    context ".get_category_options" do
      it "should return event category options" do
        expect(EventLogs::MonitoredEvent.get_category_options).to eq [:login, :osse]
      end

      it "should return event category options for given subject" do
        expect(EventLogs::MonitoredEvent.get_category_options(@monitored_event.subject_hbx_id)).to eq [:login]
      end
    end

    context ".fetch_event_logs" do
      let(:params) { { account: @user.email, event_category: :login } }
      it "should return event logs" do
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given subject" do
        params[:subject_hbx_id] = @monitored_event.subject_hbx_id
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given account" do
        params[:account] = @monitored_event.account_hbx_id
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given account username" do
        params[:account] = @monitored_event.account_username
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).size).to eq(1)
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given event start date" do
        params[:event_start_date] = @monitored_event.event_time.to_date
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).size).to eq(1)
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given event end date" do
        params[:event_end_date] = @monitored_event.event_time.to_date
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given event start and end date" do
        params[:event_start_date] = @monitored_event.event_time.to_date
        params[:event_end_date] = @monitored_event.event_time.to_date
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return event logs for given account and event start date" do
        params[:account] = @monitored_event.account_hbx_id
        params[:event_start_date] = @monitored_event.event_time.to_date
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).size).to eq(1)
        expect(EventLogs::MonitoredEvent.fetch_event_logs(params).first).to eq @monitored_event
      end

      it "should return all event logs if no params are passed" do
        expect(EventLogs::MonitoredEvent.fetch_event_logs({}).count).to eq(2)
      end
    end

  end

end
