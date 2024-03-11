# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionConcern, type: :model do

  let(:dummy_class)  { Class.new { include SessionConcern } }
  let(:subject) { dummy_class.new }

  before :each do
    Thread.current[:current_user] = nil
    Thread.current[:current_session_values] = nil
  end

  describe '#current_user' do

    it 'returns nil if no user is set in the thread' do
      Thread.current[:current_user] = nil

      expect(subject.current_user).to be_nil
    end

    it 'returns the current user from the thread' do
      user = build(:user)
      Thread.current[:current_user] = user

      expect(subject.current_user).to eq(user)
    end
  end

  describe '#session' do

    let(:session) do
      {
        "portal" => "exchanges/hbx_profiles",
        "warden.user.user.session" => {
          "last_request_at" => "1709818105"
        },
        "login_token" => "kTZM8ysv853JSva_x7zk",
        "original_application_type" => "phone",
        "last_market_visited" => "individual",
        "person_id" => BSON::ObjectId('65e9c0bca54d75774749ab81'),
        "session_id" => "ea7d5c32df2e0afc099128abab941400"
      }
    end

    let(:expected_keys) { ["portal", "warden.user.user.session", "login_token", "session_id"] }

    it 'returns empty hash if no session is set in the thread' do
      Thread.current[:current_session_values] = nil

      expect(subject.session).to eq({})
    end

    it 'returns the current user from the thread' do
      Thread.current[:current_session_values] = session

      expect(subject.session).to eq(session.slice(*expected_keys))
    end
  end

  describe '#system_account' do

    context 'when system email is not present' do
      before do
        allow(EnrollRegistry[:aca_event_logging]).to receive_message_chain(:setting, :item).and_return(nil)
      end

      it 'returns nil' do
        expect(subject.system_account).to be_nil
      end
    end

    context 'when system email is present' do
      let(:system_email) { 'admin@dc.gov' }
      let!(:system_user) { create(:user, email: system_email) }

      before do
        allow(EnrollRegistry[:aca_event_logging]).to receive_message_chain(:setting, :item).and_return(system_email)
      end

      it 'returns the system account user' do
        expect(subject.system_account).to eq(system_user)
      end
    end
  end
end
