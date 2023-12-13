# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operations::EventLogs::Store,
               type: :model,
               dbclean: :after_each do
  let(:user) { FactoryBot.create(:user) }
  let(:person) { FactoryBot.create(:person, user: user) }

  let(:session_details) do
    {
      session_id: SecureRandom.uuid,
      login_session_id: SecureRandom.uuid,
      portal: "http://dchealthlink.com"
    }
  end

  let(:payload) do
    {
      account_id: user.id.to_s,
      subject_gid: person.to_global_id.uri.to_s,
      message_id: SecureRandom.uuid,
      trigger: "eligibility_create",
      event_category: :osse_eligibility,
      event_time: DateTime.now.to_s,
      session_detail: session_details
    }
  end

  let(:headers) do
    {
      correlation_id: SecureRandom.uuid,
      host_id: "https://demo.dceligibility.assit.org"
    }
  end

  context "with input params" do
    it "should return success" do
      result = described_class.new.call(payload: payload, headers: headers)

      expect(result).to be_success
    end

    it "should persist event log" do
      described_class.new.call(payload: payload, headers: headers)

      expect(EventLogs::PersonEventLog.count).to eq 1
      event_log = EventLogs::PersonEventLog.first
      expect(event_log.account_id.to_s).to eq user.id.to_s
      expect(event_log.subject_gid).to eq person.to_global_id.uri.to_s

      session_detail = event_log.session_detail
      expect(session_detail.session_id).to eq session_details[:session_id]
      expect(session_detail.login_session_id).to eq session_details[
           :login_session_id
         ]
      expect(session_detail.portal).to eq session_details[:portal]
    end
  end
end
