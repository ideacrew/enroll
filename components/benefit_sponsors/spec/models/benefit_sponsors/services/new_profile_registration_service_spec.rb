require 'rails_helper'
require File.join(File.dirname(__FILE__), "..", "..", "..", "support/benefit_sponsors_site_spec_helpers")

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::NewProfileRegistrationService, type: :model, :dbclean => :after_each do

    subject { BenefitSponsors::Services::NewProfileRegistrationService }
    let!(:security_question)  { FactoryBot.create_default :security_question }
    let!(:site) { ::BenefitSponsors::SiteSpecHelpers.create_cca_site_with_hbx_profile_and_benefit_market }
    let!(:general_org) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
    let!(:employer_profile) { general_org.employer_profile }
    let(:broker_agency) {FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site)}
    let!(:broker_agency_profile) {broker_agency.broker_agency_profile}
    let!(:user) { FactoryBot.create(:user)}
    let!(:person) { FactoryBot.create(:person, emails:[ FactoryBot.build(:email, kind:'work') ], user_id: user.id) }
    let!(:active_employer_staff_role) {FactoryBot.create(:benefit_sponsor_employer_staff_role, aasm_state:'is_active', benefit_sponsor_employer_profile_id: employer_profile.id, person: person)}
    let!(:broker_role) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person) }

    shared_examples_for "should return profile type" do |profile_type|

      it "profile_type #{profile_type}" do
        params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id : broker_agency_profile.id}
        service = subject.new params
        expect(service.pluck_profile_type params[:profile_id]).to eq profile_type
      end

    end

    describe ".pluck_profile_type" do
      it_behaves_like "should return profile type", "benefit_sponsor"
      it_behaves_like "should return profile type", "broker_agency"
    end

    shared_examples_for "should return form for profile" do |profile_type|

      it "should return form for existing #{profile_type} type" do
        params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id : broker_agency_profile.id}
        service = subject.new params
        build_hash = service.build params
        expect(build_hash[:profile_type]).to eq profile_type
        expect(build_hash[:organization][:legal_name]).to eq profile_type == "benefit_sponsor" ?  employer_profile.legal_name : broker_agency_profile.legal_name
      end

      it "should return new form for #{profile_type} type" do
        params = { profile_type: profile_type}
        service = subject.new params
        build_hash = service.build params
        expect(build_hash[:profile_type]).to eq profile_type
        expect(build_hash[:organization][:legal_name]).to eq nil
      end
    end

    describe ".build" do
      it_behaves_like "should return form for profile", "benefit_sponsor"
      it_behaves_like "should return form for profile", "broker_agency"
    end

    shared_examples_for "should find profile and return form for profile" do |profile_type|

      it "should return form for #{profile_type} type" do
        params = { profile_id: profile_type == "benefit_sponsor" ? employer_profile.id.to_s : broker_agency_profile.id, profile_type:profile_type}
        service = subject.new params
        find_hash = service.find
        expect(find_hash[:profile_type]).to eq profile_type
        expect(find_hash[:organization][:legal_name]).to eq profile_type == "benefit_sponsor" ?  employer_profile.legal_name : broker_agency_profile.legal_name
      end
    end

    describe ".find" do
      it_behaves_like "should find profile and return form for profile", "benefit_sponsor"
      it_behaves_like "should find profile and return form for profile", "broker_agency"
    end

    describe ".is_benefit_sponsor_already_registered?" do
      context "Should return when person found" do
        before :each do
          allow(user).to receive(:person).and_return(person)
          @form = BenefitSponsors::Organizations::OrganizationForms::RegistrationForm.new(profile_type: "benefit_sponsor")
          @result = subject.new(@form).is_benefit_sponsor_already_registered?(user, @form)
        end

        it 'should return false for when found employer profile id' do
          expect(@result).to eq false
        end
      end
    end
  end
end
