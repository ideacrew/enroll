require 'rails_helper'

RSpec.describe ShopEmployerNotices::InitialEmployerDenialNotice, dbclean: :after_each do

  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:person){ FactoryGirl.create :person}
  let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :dc) }
  let(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
  let(:employer_profile)    { organization.employer_profile }
  let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let(:benefit_application) { build(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'draft',
    :fte_count => 55,
    :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Denial of Initial Employer Application/Request for Clarifying Documentation',
                            :notice_template => 'notices/shop_employer_notices/2_initial_employer_denial_notice',
                            :notice_builder => 'ShopEmployerNotices::InitialEmployerDenialNotice',
                            :event_name => 'initial_employer_denial',
                            :mpi_indicator => 'MPI_SHOP2B',
                            :title => "Employer Denial Notice"})
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
        expect{ShopEmployerNotices::InitialEmployerDenialNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::InitialEmployerDenialNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::InitialEmployerDenialNotice.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name.titleize
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "append_data" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      benefit_application.submit_for_review!
      @employer_notice = ShopEmployerNotices::InitialEmployerDenialNotice.new(employer_profile, valid_parmas)
    end

    it "should append necessary information" do
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.warnings).to eq ["primary business address not located in the District of Columbia", "Full Time Equivalent must be 1-50"]
    end
  end

end