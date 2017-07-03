require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice do
  let(:employer_profile){ create :employer_profile}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Employer Annual Renewal - Denial of Eligibility',
                            :notice_template => 'notices/shop_employer_notices/employer_renewal_eligibility_denial_notice',
                            :notice_builder => 'ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice',
                            :mpi_indicator => 'MPI_SHOP33',
                            :title => "Employer Annual Renewal - Denial of Eligibility"})
                          }
    let(:valid_params) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :template => application_event.notice_template
    }}

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)
    end
    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "append_data" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalEligibilityDenialNotice.new(employer_profile, valid_params)
    end
    it "should append necessary" do
      plan_year = employer_profile.plan_years.first
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq plan_year.start_on
    end
  end

end