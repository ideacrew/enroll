# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventLogsController, :type => :controller do
  let(:user) { FactoryBot.create(:user) }
  let!(:person) { FactoryBot.create(:person, user: user) }
  let(:hbx_staff_role) { FactoryBot.create(:hbx_staff_role, person: person) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:payload) do
    {
      title: "Fake Event"
    }
  end
  let(:person_event_log) { FactoryBot.create(:people_eligibilities_event_log, account: user, payload: payload.to_json) }

  before :each do
    allow(user).to receive(:has_hbx_staff_role?).and_return true
    sign_in user
  end

  context "#index" do

    it "should assign event logs with params" do
      event1 = FactoryBot.create(:monitored_event, account_username: user.email, monitorable: person_event_log, subject_hbx_id: person.hbx_id)
      FactoryBot.create(:monitored_event, account_username: user.email, monitorable: person_event_log)
      get :index, params: {events: [event1.id]}, format: :js
      expect(assigns(:event_logs).count).to eq 1
      expect(assigns(:event_logs).first.subject_hbx_id).to eq person.hbx_id
    end

    it "should fetch none without a param" do
      get :index, format: :js
      expect(assigns(:event_logs).count).to eq 0
    end

    it "should render index" do
      get :index, params: {}, format: :js
      expect(response).to render_template(:index)
    end

    context "csv" do
      it "should render csv" do
        get :index, params: {format: :csv}
        expect(response.header["Content-Type"]).to eq "text/csv"
      end
    end
  end
end
