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

  let(:subject_gid) { person.to_global_id.uri.to_s }

  let(:payload) { { sample: true } }

  let(:headers) do
    {
      correlation_id: SecureRandom.uuid,
      message_id: SecureRandom.uuid,
      host_id: "https://demo.dceligibility.assit.org",
      subject_gid: subject_gid,
      resource_gid: subject_gid,
      event_time: DateTime.now,
      event_name: event_name,
      account: {
        id: user.id.to_s,
        session: session_details
      }
    }
  end

  let(:event_name) do
    "events.people.eligibilities.ivl_osse_eligibility.eligibility_created"
  end

  before { allow(subject).to receive(:event_logging_enabled?).and_return(true) }

  subject { described_class.new }

  context "when not able to locate subject resource" do
    let(:event_name) { "events.people.eligibilities.eligibility_created" }

    it "should fail" do
      result = subject.call(payload: payload, headers: headers)

      expect(result).to be_failure
      expect(
        result.failure
      ).to match(/uninitialized constant AcaEntities::PeopleEventLogContract/)
    end
  end

  context "with input params" do
    it "should return success" do
      result = subject.call(payload: payload, headers: headers)

      expect(result).to be_success
    end

    it "should persist event log" do
      subject.call(payload: payload, headers: headers)

      expect(People::EligibilitiesEventLog.count).to eq 1
      event_log = People::EligibilitiesEventLog.first
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

  context "when event logging is disabled" do
    before do
      allow(subject).to receive(:event_logging_enabled?).and_return(false)
    end

    it "should fail" do
      result = subject.call(payload: payload, headers: headers)

      expect(result).to be_failure
      expect(result.failure).to eq "Event logging is not enabled"
    end
  end
end
