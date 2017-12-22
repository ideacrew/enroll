require 'rails_helper'

RSpec.describe ShopGeneralAgencyNotices::DefaultGeneralAgencyFiredNotice, :dbclean => :after_each do
  let!(:hbx_profile) { FactoryGirl.create(:hbx_profile, organization: organization) }
  let!(:person) { FactoryGirl.create(:person, :with_work_email) }
  let!(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  let!(:general_agency_staff_role) {FactoryGirl.create(:general_agency_staff_role, general_agency_profile: general_agency_profile, person: person)}
  let!(:organization) {FactoryGirl.create(:organization)}
  let!(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile, organization: organization ) }
  let!(:broker_role) {  broker_agency_profile.primary_broker_role }
  let!(:application_event){ double("ApplicationEventKind",{
                            :name =>'Default GA Hired - include date of appointment/termination',
                            :notice_template => 'notices/shop_general_agency_notices/broker_fires_default_ga_notice',
                            :notice_builder => 'ShopGeneralAgencyNotices::DefaultGeneralAgencyFiredNotice',
                            :mpi_indicator => 'SHOP_D089',
                            :event_name => 'broker_fires_default_ga_notice',
                            :title => "Broker has removed you as their default general agency"})
                          }
  let!(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :options => {
        :broker_agency_profile_id => broker_agency_profile.id
      }
  }}

  before do
    @general_agency_notice = ShopGeneralAgencyNotices::DefaultGeneralAgencyFiredNotice.new(general_agency_profile, valid_params)
    allow(general_agency_profile).to receive(:general_agency_staff_roles).and_return([general_agency_staff_role])
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{ShopGeneralAgencyNotices::DefaultGeneralAgencyFiredNotice.new(general_agency_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopGeneralAgencyNotices::DefaultGeneralAgencyFiredNotice.new(general_agency_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    it "should build notice with all necessory info" do
      @general_agency_notice.build
      expect(@general_agency_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
  end

  describe "append data" do
    it "should append data" do
      @general_agency_notice.append_data
      expect(@general_agency_notice.notice.general_agency.broker_fullname).to eq broker_role.person.full_name
    end
  end

  describe "should render template" do
    it "render broker_fires_default_ga_notice" do
      expect(@general_agency_notice.template).to eq "notices/shop_general_agency_notices/broker_fires_default_ga_notice"
    end
  end

  describe "for generating pdf" do
    it "should generate pdf" do
      @general_agency_notice.build
      @general_agency_notice.append_data
      file = @general_agency_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
