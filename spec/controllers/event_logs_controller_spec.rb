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
    let(:event_log_params) { { "family" => family.id } }

    it "should assign event logs with a param" do
      FactoryBot.create(:monitored_event, account_username: user.email, monitorable: person_event_log, subject_hbx_id: person.hbx_id)
      FactoryBot.create(:monitored_event, account_username: user.email, monitorable: person_event_log)
      get :index, params: event_log_params, format: :js
      expect(assigns(:event_logs).count).to eq 1
      expect(assigns(:event_logs).first[:title]).to eq "FAKE EVENT"
      expect(assigns(:event_logs).first[:subject]).to eq person.full_name
    end

    it "should assign event logs without a param" do
      get :index, format: :js
      expect(assigns(:event_logs).count).to eq 2
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
