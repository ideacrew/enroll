require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "components", "fix_organization")
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe FixOrganization, dbclean: :after_each do
  let(:given_task_name) { "fix_organization" }
  subject { FixOrganization.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update the fein of an Employer" do
    let(:employer_organization)  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_organization_2)  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    before(:each) do
      ENV["action"] = "update_fein"
      ENV["organization_fein"] = employer_organization.fein
      ENV["correct_fein"] = "987654321"
    end
    context "updating the fein when the correct information is provided" do
      it "should change fein" do
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).to eq "987654321"
      end
    end
    context "not updating the fein when the given fein is already assigned" do
      it "should not change fein" do
        employer_organization_2.fein=("987654321")
        employer_organization_2.save!
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
      end
    end
    context "not updating the fein when there is no organization with the fein" do
      it "should not change fein" do
        employer_organization.fein=("111111111")
        employer_organization.save!
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
      end
    end
    context "not updating the fein when there is no organization with the fein" do
      it "should not change fein" do
        employer_organization.fein=("111111111")
        employer_organization.save!
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
      end
    end
    context "not updating the fein when there is no organization with the fein" do
      it "should not change fein" do
        ENV["action"]= "some_other_action"
        subject.migrate
        employer_organization.reload
        expect(employer_organization.fein).not_to eq "987654321"
      end
    end
  end


  describe "swap the fein of an Employer" do
    let(:employer_organization)  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site, fein: "111111111") }
    let(:employer_organization_2)  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site, fein: "987654321") }
    let(:site)  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    before(:each) do
      ENV["action"] = "swap_fein"
      ENV["organization_fein"] = employer_organization.fein
      ENV["correct_fein"] = employer_organization_2.fein
    end
    context "updating the fein when the correct information is provided" do
      it "should swap fein when organization is present" do
        expect(employer_organization.fein).to eq "111111111"
        expect(employer_organization_2.fein).to eq "987654321"
        subject.migrate
        employer_organization.reload
        employer_organization_2.reload
        expect(employer_organization.fein).to eq "987654321"
        expect(employer_organization_2.fein).to eq "111111111"
      end
    end
    context "updating the fein when the incorrect information is provided" do
      it "should not swap fein when organization is not present" do
        employer_organization_2.update_attributes(:fein => "222222222")
        expect(employer_organization.fein).to eq "111111111"
        expect(employer_organization_2.fein).to eq "222222222"
        subject.migrate
        employer_organization.reload
        employer_organization_2.reload
        expect(employer_organization.fein).to eq "111111111"
        expect(employer_organization_2.fein).to eq "222222222"
      end
    end
  end

  describe "update employer attestation for profiles with attestation unsubmitted and document submitted" do

    let(:employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }
    let(:site)                    { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:employer_attestation)   { FactoryBot.build(:employer_attestation, aasm_state:'unsubmitted') }
    let!(:benefit_sponsorship)   { employer_profile.add_benefit_sponsorship }
    before(:each) do
      ENV["action"] = "approve_attestation"
      ENV["organization_fein"] = employer_organization.fein
      employer_profile.employer_attestation = employer_attestation
      benefit_sponsorship.save
      employer_profile.save
    end


    context "when employer has an attestation is in unsubmitted state and document in submitted state" do

      before do
        employer_profile.employer_attestation.employer_attestation_documents.create(title: "test", aasm_state:'submitted')
        employer_profile.save
      end

      it "should accept the document and approve the attestation" do
        expect(employer_attestation.aasm_state).to eq "unsubmitted"
        expect(employer_attestation.employer_attestation_documents.first.aasm_state).to eq "submitted"
        subject.migrate
        employer_profile.reload
        employer_attestation.reload
        expect(employer_attestation.aasm_state).to eq "approved"
        expect(employer_attestation.employer_attestation_documents.first.aasm_state).to eq "accepted"
      end
    end
    context "when employer has an attestation is in denied state and document in rejected state" do

      before do
        employer_profile.employer_attestation.update_attributes!(aasm_state: 'denied')
        employer_profile.employer_attestation.employer_attestation_documents.create(title: "test", aasm_state:'rejected')
        employer_profile.save
      end

      it "should approve the attestation when no documents are present for conversion group" do
        expect(employer_attestation.aasm_state).to eq "denied"
        expect(employer_attestation.employer_attestation_documents.first.aasm_state).to eq "rejected"
        subject.migrate
        employer_profile.reload
        employer_attestation.reload
        expect(employer_attestation.aasm_state).to eq "approved"
        expect(employer_attestation.employer_attestation_documents.first.aasm_state).to eq "accepted"
      end
    end

    context "when employer is mid_plan_year_conversion " do

      before do
        benefit_sponsorship.source_kind = :mid_plan_year_conversion
        benefit_sponsorship.save
      end

      it "should approve the attestation when no documents are present for mid plan year conversion group" do
        expect(employer_attestation.aasm_state).to eq "unsubmitted"
        expect(employer_attestation.employer_attestation_documents).to eq []
        subject.migrate
        employer_profile.reload
        employer_attestation.reload
        expect(employer_attestation.aasm_state).to eq "approved"
      end
    end
    context "when employer is mid_plan_year_conversion " do

      before do
        benefit_sponsorship.source_kind = :conversion
        benefit_sponsorship.save
      end

      it "should approve the attestation when no documents are present for conversion group" do
        expect(employer_attestation.aasm_state).to eq "unsubmitted"
        expect(employer_attestation.employer_attestation_documents).to eq []
        subject.migrate
        employer_profile.reload
        employer_attestation.reload
        expect(employer_attestation.aasm_state).to eq "approved"
      end
    end
  end

  describe "update employer broker agency account of an Employer" do

    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:organization) { benefit_sponsorship.organization }
    let(:employer_profile) { organization.employer_profile }
    let(:active_benefit_sponsorship) { benefit_sponsorship }
    let(:old_broker_organization) { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: organization.site)}
    let!(:old_broker_agency_profile) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: old_broker_organization, market_kind: 'shop') }
    let!(:old_broker_role) { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: old_broker_agency_profile.id) }
    let!(:broker_agency_account) { FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, benefit_sponsorship: active_benefit_sponsorship, is_active: true, broker_agency_profile: old_broker_agency_profile) }
    let(:broker_organization) { FactoryBot.build(:benefit_sponsors_organizations_exempt_organization, site: organization.site)}
    let!(:broker_agency_profile1) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, market_kind: 'shop', legal_name: 'Legal Name1') }
    let!(:broker_role) { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id) }

    context "updating broker agency account details to correct information is provided" do
      before(:each) do
        ENV['action'] = 'update_employer_broker_agency_account'
        ENV['organization_fein'] = organization.fein
        ENV['npn'] = broker_role.npn
      end

      it "should update broker agency account when organization is present" do
        expect(active_benefit_sponsorship.active_broker_agency_account.is_active).to eq true
        subject.migrate
        active_benefit_sponsorship.reload
        expect(active_benefit_sponsorship.broker_agency_accounts.unscoped.first.is_active).to eq false
        expect(active_benefit_sponsorship.active_broker_agency_account.writing_agent_id).to eq broker_role.id
        expect(active_benefit_sponsorship.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id).to eq broker_agency_profile1.id
      end
    end

    context "updating broker agency account details to correct information is provided" do

      before(:each) do
        ENV['action'] = 'update_employer_broker_agency_account'
        ENV['organization_fein'] = active_benefit_sponsorship.organization.fein
        ENV['npn'] = ""
      end

      it "should not update broker agency account when organization is present" do
        subject.migrate
        active_benefit_sponsorship.reload
        expect(active_benefit_sponsorship.active_broker_agency_account.writing_agent_id).not_to eq broker_role.id
        expect(active_benefit_sponsorship.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id).not_to eq broker_agency_profile1.id
      end
    end
  end
end