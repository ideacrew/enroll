require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::Organization, type: :model do


    context "a broker gains access to an employer's information for plan_design" do
      let(:employer_name)         { "Classy Cupcakes, Corp" }
      let(:broker_name)           { "Busy Brokers, Inc" }
      let!(:employer_organization) { SponsoredBenefits::Organizations::ExemptOrganization.new(legal_name: employer_name) }
      let!(:broker_organization)   { SponsoredBenefits::Organizations::ExemptOrganization.new(legal_name: broker_name) }

      before { broker_organization.plan_design_subjects << employer_organization }

      it "the employer should appear in the broker's subject list" do
        expect((broker_organization.plan_design_subjects).size).to eq 1
        expect(broker_organization.plan_design_subjects.first).to eq employer_organization
      end

      # it "the broker should appear in the employer's author list" do
      #   expect((employer_organization.plan_design_authors).size).to eq 1
      #   expect(employer_organization.plan_design_authors.first).to eq broker_organization
      # end

      it "the broker should appear in the employer's author ID list" do
        expect((employer_organization.plan_design_author_ids).size).to eq 1
        expect(employer_organization.plan_design_author_ids.first).to eq broker_organization.id
      end

      context "and the broker creates a plan_design_organization for the employer" do
        let(:customer)                  { broker_organization.plan_design_subjects.first } 
        let!(:plan_design_organization) { broker_organization.plan_design_organizations.build(subject_organization: customer) }

        it "the broker should have a new plan_design_organization instance" do
          expect(broker_organization.plan_design_organizations.first).to eq plan_design_organization
        end

        it "and the new plan_design_organization instance should reference the employer's (subject) organization" do
          expect(broker_organization.plan_design_organizations.first.subject_organization).to eq customer
        end
      end
    end

  end
end
