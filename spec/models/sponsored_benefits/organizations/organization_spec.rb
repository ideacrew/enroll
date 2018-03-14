require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::Organization, type: :model do

    context "an Organization is hierarchical with a top level agency and child divisions" do
      let(:agency_name)             { "Multinational Conglomerate, Ltd" }
      let(:business_division_name)  { "Business Ops" }
      let(:it_division_name)        { "Information Technology Ops" }
      let(:it_devops_division_name) { "DevOps" }
      let(:agency)                  { SponsoredBenefits::Organizations::ExemptOrganization.new(legal_name: agency_name) }
      let(:it_division)             { SponsoredBenefits::Organizations::ExemptOrganization.new(legal_name: it_division_name) }

      before do
        agency.divisions.build(legal_name: business_division_name) 
        agency.divisions << it_division
        it_division.divisions.build(legal_name: it_devops_division_name)
      end

      it "the top level Agency should have two divisions" do
        expect(agency.divisions.size).to eq 2
      end

      it "IT division should have one division" do
        expect(it_division.divisions.first.legal_name).to eq it_devops_division_name
      end

      it "the IT devops division should have two agency parents" do
        expect(it_division.divisions.first.agency.legal_name).to eq it_division_name
        expect(it_division.divisions.first.agency.agency.legal_name).to eq agency_name
        expect(it_division.divisions.first.agency.agency.agency).to be_nil
      end
    end


    context "a broker gains access to an employer's information for plan_design" do
      let(:employer_name)           { "Classy Cupcakes, Corp" }
      let(:broker_name)             { "Busy Brokers, Inc" }
      let!(:employer_organization)  { SponsoredBenefits::Organizations::ExemptOrganization.new(legal_name: employer_name) }
      let!(:broker_organization)    { SponsoredBenefits::Organizations::ExemptOrganization.new(legal_name: broker_name) }

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
