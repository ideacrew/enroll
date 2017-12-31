require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignOrganization, type: :model, dbclean: :around_each do

    describe "#expire proposals for non Prospect Employer" do
      let!(:organization) { create(:plan_design_organization,
                              customer_profile_id: "1234",
                              owner_profile_id: "5678",
                              legal_name: "ABC Company",
                              sic_code: "0345" ) }

      context "when in an expirable state" do
        before(:each) do
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "draft"})
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "draft"})
          organization.expire_proposals
        end

        it "should change the status to expired" do
          expect(organization.plan_design_proposals[0].aasm_state).to eq "expired"
          expect(organization.plan_design_proposals[1].aasm_state).to eq "expired"
        end
      end

      context "when in NON expirable states" do
        before(:each) do
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "published"})
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "claimed"})
          organization.expire_proposals
        end

        it "should have published as the new aasm state" do
          expect(organization.plan_design_proposals[0].aasm_state).to_not eq "expired"
          expect(organization.plan_design_proposals[1].aasm_state).to_not eq "expired"
        end
      end
    end

    describe "#expire proposals for Prospect" do
      let!(:organization) { create(:plan_design_organization,
                        customer_profile_id: nil,
                        owner_profile_id: "5678",
                        legal_name: "ABC Company",
                        sic_code: "0345" ) }

      context "when in an expirable state" do
        before(:each) do
          organization.plan_design_proposals.build({title: "new proposal for new client 1", aasm_state: "draft"})
        end

        it "should NOT change the status to expired" do
          expect(organization.plan_design_proposals[0].can_be_expired?).to eq false
        end
      end
    end

  end
end
