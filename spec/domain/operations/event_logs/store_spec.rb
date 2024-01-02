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
      event_name: "events.people.eligibilities.ivl_osse_eligibility.eligibility_terminated",
      account: {
        id: user.id.to_s,
        session: session_details
      }
    }
  end

  #   {
  #        :subject_gid => "gid://enroll/Person/5d8501a31bdce254e7715bb7",
  #       :resource_gid => "gid://enroll/IvlOsseEligibilities::IvlOsseEligibility/650425e688d2415d2b9130df",
  #         :event_time => 2024-01-01 12:50:31 -0500,
  #         :event_name => "events.people.eligibilities.ivl_osse_eligibility.eligibility_terminated",
  #            :account => {
  #         :session => {
  #                                 :portal => "http://localhost:3000/exchanges/hbx_profiles",
  #             :"warden.user.user.session" => {
  #                 :last_request_at => 1704131431
  #             },
  #                            :login_token => "mewKXYvzF5aHZ6r-BAXa",
  #                              :person_id => "5d8501a31bdce254e7715bb7",
  #                             :session_id => "845b30bbb6f0b791d0753f36d93a731d"
  #         },
  #              :id => "5d680e26d7b2f7110f31170d"
  #     },
  #         :message_id => "a564a184-f64b-49e1-b735-4ac63058e409",
  #     :correlation_id => "157aa53f-98ef-4a02-b658-3a1b05d7c2dc",
  #            :host_id => "enroll"
  # }

  before { allow(subject).to receive(:event_logging_enabled?).and_return(true) }

  subject { described_class.new }

  context "when not able to locate subject resource" do
    let(:subject_gid) { "#{person.to_global_id.uri}9" }

    it "should fail" do
      result = subject.call(payload: payload, headers: headers)

      expect(result).to be_failure
      expect(
        result.failure
      ).to eq "Unable to find resource for subject_gid: #{subject_gid}"
    end
  end

  context "with input params" do
    it "should return success" do
      result = subject.call(payload: payload, headers: headers)

      expect(result).to be_success
    end

    it "should persist event log" do
      subject.call(payload: payload, headers: headers)

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
