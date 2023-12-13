# frozen_string_literal: true

require "spec_helper"

RSpec.describe Operations::EventLogs::Create,
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

  let(:params) do
    {
      account_id: user.id.to_s,
      subject_gid: person.to_global_id.uri.to_s,
      message_id: SecureRandom.uuid,
      trigger: "eligibility_create",
      correlation_id: SecureRandom.uuid,
      host_id: "https://demo.dceligibility.assit.org",
      event_category: :osse_eligibility,
      event_time: DateTime.now,
      session_detail: session_details,
      resource_class: resource_class
    }
  end

  let(:resource_class) { "Person" }

  context "when resource class name is not passed" do
    let(:resource_class) { nil }

    it "should fail" do
      result = described_class.new.call(params)

      expect(result).to be_failure
      expect(result.failure).to eq "resource class name missing"
    end
  end

  context "with valid params" do
    it "should create entity" do
      result = described_class.new.call(params)

      expect(result).to be_success
      expect(result.success).to be_a(AcaEntities::EventLogs::PersonEventLog)
    end
  end
end
