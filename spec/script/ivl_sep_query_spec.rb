# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "script", "ivl_sep_query")

describe "script/ivl_sep_query.rb" do

  let!(:ivl_person)       { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:ivl_family)       { FactoryBot.create(:family, :with_primary_family_member, person: ivl_person) }
  let!(:ivl_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: ivl_family.active_household,
                      family: ivl_family,
                      kind: "individual",
                      is_any_enrollment_member_outstanding: true,
                      aasm_state: "coverage_termianted",
                      terminated_on: TimeKeeper.date_of_record + 1.month,
                      workflow_state_transitions: [workflow_state_transitions])
  end
  let!(:ivl_enrollment_member) do
    FactoryBot.create(:hbx_enrollment_member,
                      is_subscriber: true,
                      applicant_id: ivl_family.primary_applicant.id, hbx_enrollment: ivl_enrollment,
                      eligibility_date: TimeKeeper.date_of_record, coverage_start_on: TimeKeeper.date_of_record)
  end
  let!(:workflow_state_transitions)  { FactoryBot.build(:workflow_state_transition, to_state: 'coverage_terminated', transition_at: Time.zone.now - 5.minutes)}
  let!(:glue_event_queue_name) { "dc0.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

  context "user/admin termianted enrollment" do

    it "should notify enrollment termination" do
      expect(IvlEnrollmentsPublisher).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                               {reply_to: glue_event_queue_name, hbx_enrollment_id: ivl_enrollment.hbx_id,
                                                                enrollment_action_uri: "urn:openhbx:terms:v1:enrollment#terminate_enrollment"})
      ivl_sep_script = File.join(Rails.root, "script/ivl_sep_query.rb")
      load ivl_sep_script
    end
  end

  context "carrier initiated termianted enrollment" do

    before do
      ivl_enrollment.carrier_initiated_term = true
      ivl_enrollment.save
    end

    it "should not notify enrollment termination" do
      expect(IvlEnrollmentsPublisher).not_to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated",
                                                                   {reply_to: glue_event_queue_name, hbx_enrollment_id: ivl_enrollment.hbx_id,
                                                                    enrollment_action_uri: "urn:openhbx:terms:v1:enrollment#terminate_enrollment"})
      ivl_sep_script = File.join(Rails.root, "script/ivl_sep_query.rb")
      load ivl_sep_script
    end
  end

end
