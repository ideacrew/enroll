require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployerBrokerFiredNotice, dbclean: :after_each do
  before(:all) do

    @site =  FactoryBot.create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca)
    @organization = FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: @site) 
    @employer_profile = @organization.employer_profile
    @benefit_sponsorship = @employer_profile.add_benefit_sponsorship
    @broker_agency_organization = FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: @site)
    @broker_agency_profile = @broker_agency_organization.broker_agency_profile
    @broker_agency_account = FactoryBot.create(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: @broker_agency_profile, benefit_sponsorship: @benefit_sponsorship)
    @broker_role = FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: @broker_agency_profile.id)
    @broker_agency_organization.broker_agency_profile.update_attributes(primary_broker_role: @broker_role)
    @broker_role.update_attributes(broker_agency_profile_id: @broker_agency_organization.broker_agency_profile.id)
    @broker_agency_organization.broker_agency_profile.approve!
    @employer_profile.broker_role_id = @broker_role.id
    @employer_profile.hire_broker_agency(@broker_agency_organization.broker_agency_profile)
    @employer_profile.save!
  end

  let(:organization) { @organization }
  let(:employer_profile){@employer_profile }
  let(:person) { @broker_role.person }
  let(:broker_role) { @broker_role }
  let(:broker_agency_account) { @broker_agency_account }

  #add person to broker agency profile
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Broker fired',
      :notice_template => 'notices/shop_employer_notices/employer_broker_fired_notice',
      :notice_builder => 'ShopEmployerNotices::EmployerBrokerFiredNotice',
      :mpi_indicator => 'MPI_SHOP52',
      :event_name => 'employer_broker_fired',
      :title => "Confirmation of Broker Fired to Employer"})
  }
  let(:valid_params) {{
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
        expect{ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
      before do
        allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
        @employer_notice = ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)
      end
      # builder is not in use and not updated as per new model(will work in DC)
      xit "should build notice with all necessary info" do
        @employer_notice.build
        expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
        expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
        expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
      end
  end

  describe "append_data" do
    let(:employer_profile)      { @employer_profile}
    let(:broker_agency_profile) { @broker_agency_profile }
    let(:broker_agency_account) { @broker_agency_account }
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)
    end

    it "should append necessary" do
      employer_profile.fire_broker_agency
      employer_profile.save
      broker = employer_profile.broker_agency_accounts.unscoped.last.broker_agency_profile
      broker_role = broker.primary_broker_role
      person = broker_role.person
      @employer_notice.append_data
      expect(@employer_notice.notice.broker.first_name).to eq(person.first_name)
      expect(@employer_notice.notice.broker.last_name).to eq(person.last_name)
      expect(@employer_notice.notice.broker.terminated_on).to eq(employer_profile.broker_agency_accounts.unscoped.last.end_on)
      expect(@employer_notice.notice.broker.organization).to eq (broker.legal_name)
    end
  end

  describe "Rendering notice template and genearte pdf" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @eligibility_notice = ShopEmployerNotices::EmployerBrokerFiredNotice.new(employer_profile, valid_params)
    end
    it "should render notice" do
      expect(@eligibility_notice.template).to eq "notices/shop_employer_notices/employer_broker_fired_notice"
    end
    # builder is not in use and not updated as per new model(will work in DC)
    xit "should generate pdf" do
      @eligibility_notice.append_hbe
      @eligibility_notice.build
      file = @eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
