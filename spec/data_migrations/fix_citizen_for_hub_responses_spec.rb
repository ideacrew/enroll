require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_citizen_for_hub_responses")

ACCEPTABLE_STATES = %w(us_citizen naturalized_citizen alien_lawfully_present lawful_permanent_resident)
NOT_ACCEPTABLE_STATES = %w(indian_tribe_member undocumented_immigrant not_lawfully_present_in_us non_native_not_lawfully_present_in_us ssn_pass_citizenship_fails_with_SSA non_native_citizen)
STATES_TO_FIX = %w(not_lawfully_present_in_us non_native_not_lawfully_present_in_us ssn_pass_citizenship_fails_with_SSA non_native_citizen)

describe UpdateCitizenStatus do
  subject { UpdateCitizenStatus.new("fix_citizen_for_hub_responses", double(:current_scope => nil)) }
  let(:person) { FactoryGirl.create(:person, :with_consumer_role) }

  shared_examples_for "people whose citizen_state was changed" do |action, old_state, new_state, result|
    it "#{action} #{old_state} citizen status to #{new_state}" do
      expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq(result)
    end
  end

  context "citizen state is the same for all versions" do
    before do
      person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: "us_citizen", vlp_authority: "ssa")
      allow(subject).to receive(:get_people).and_return([person])
      subject.migrate
    end

    it "doesn't change citizen status" do
      expect(person.consumer_role.lawful_presence_determination.citizen_status).to eq("us_citizen")
    end
  end

  STATES_TO_FIX.each do |state|
    context "citizen state has been changed" do
      describe "was in one of the legal state but has been changed to not legal" do
        #fix it from history if the source doesn't have vlp_authority or authority is curam
        before do
          person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: state, vlp_authority: "ssa")
          allow(subject).to receive(:get_people).and_return([person])
          subject.migrate
        end
        it_behaves_like "people whose citizen_state was changed", "change", state, "us_citizen", "us_citizen"
      end

      describe "was not legal but has been changed to legal" do
        #don't fix it
        before do
          person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: state, vlp_authority: "ssa")
          person.consumer_role.lawful_presence_determination.update_attributes!(citizen_status: "alien_lawfully_present", vlp_authority: "ssa")
          allow(subject).to receive(:get_people).and_return([person])
          subject.migrate
        end
        it_behaves_like "people whose citizen_state was changed", "doesn't change", "alien_lawfully_present", state, "alien_lawfully_present"
      end
    end
  end
end
