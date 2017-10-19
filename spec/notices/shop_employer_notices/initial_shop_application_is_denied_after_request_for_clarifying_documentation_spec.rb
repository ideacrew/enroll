require 'rails_helper'

RSpec.describe ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation do
  before(:all) do
    @employer_profile = FactoryGirl.create(:employer_profile)
    @broker_role =  FactoryGirl.create(:broker_role, aasm_state: 'active')
    @organization = FactoryGirl.create(:broker_agency, legal_name: "agencyone")
    @organization.broker_agency_profile.update_attributes(primary_broker_role: @broker_role)
    @broker_role.update_attributes(broker_agency_profile_id: @organization.broker_agency_profile.id)
    @organization.broker_agency_profile.approve!
    @employer_profile.broker_role_id = @broker_role.id
    @employer_profile.save!(validate: false)
  end

  let(:organization) { @organization }
  let(:employer_profile){@employer_profile }
  let(:person) { @broker_role.person }
  let(:broker_role) { @broker_role }
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: @organization.broker_agency_profile,employer_profile: @employer_profile)}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'DENIAL OF APPLICATION TO OFFER GROUP HEALTH COVERAGE IN THE MASSACHUSETTS HEALTH CONNECTOR',
      :notice_template => 'notices/shop_employer_notices/initial_shop_application_is_denied_after_request_for_clarifying_documentation',
      :notice_builder => 'ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation',
      :mpi_indicator => 'MPI_SHOP57',
      :event_name => 'employer_ineligibilty_denial_application',
      :title => "Denial Of Application To Offer Group Health Coverage In The Massachusetts Health Connector"})
  }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
  	before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
      before do
        allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
        @employer_notice = ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation.new(employer_profile, valid_parmas)
      end
      it "should build notice with all necessary info" do
        @employer_notice.build
        expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
        expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
        expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
      end
  end

  describe "Rendering notice template and genearte pdf" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @eligibility_notice = ShopEmployerNotices::InitialShopApplicationIsDeniedAfterRequestForClarifyingDocumentation.new(employer_profile, valid_parmas)
    end
    it "should render notice" do
      expect(@eligibility_notice.template).to eq "notices/shop_employer_notices/initial_shop_application_is_denied_after_request_for_clarifying_documentation"
    end
    it "should generate pdf" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      file = @eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
