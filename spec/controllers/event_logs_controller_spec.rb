# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventLogsController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }

  before :each do
    sign_in user
  end

  context "#index" do
    let(:event_log) { EventLogs::MonitoredEvent.new }
    let(:event_logs) { [event_log] }
    let(:event_log_params) { { "subject_hbx_id" => "1234" } }

    before :each do
      allow(EventLogs::MonitoredEvent).to receive(:fetch_event_logs).with(event_log_params).and_return(event_logs)
    end

    it "should assign event logs" do
      get :index, params: event_log_params, format: :js
      expect(assigns(:event_logs)).to eq event_logs
    end

    it "should render index" do
      get :index, params: event_log_params, format: :js
      expect(response).to render_template(:index)
    end

    context "csv" do
      it "should render csv" do
        get :index, params: event_log_params.merge(format: :csv)
        expect(response.header["Content-Type"]).to eq "text/csv"
      end
    end
  end
end
