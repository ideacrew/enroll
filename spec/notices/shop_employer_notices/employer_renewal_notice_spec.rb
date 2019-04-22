require 'rails_helper'

RSpec.describe ShopEmployerNotices::EmployerRenewalNotice, :dbclean => :after_each  do
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile}
  let!(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:renewal_plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on + 1.year, :aasm_state => 'renewing_draft' ) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: renewal_plan_year, title: "Benefits #{renewal_plan_year.start_on.year}") }
  let(:conversion_application_event){ double("ApplicationEventKind",{
                            :name =>'Conversion, Group Renewal Available',
                            :notice_template => 'notices/shop_employer_notices/6_conversion_group_renewal_notice',
                            :notice_builder => 'ShopEmployerNotices::EmployerRenewalNotice',
                            :event_name => 'conversion_group_renewal',
                            :mpi_indicator => 'MPI_SHOP6',
                            :title => "Welcome to OPM, Group Renewal Available"})
                          }
    let(:conversion_valid_parmas) {{
        :subject => conversion_application_event.title,
        :mpi_indicator => conversion_application_event.mpi_indicator,
        :event_name => conversion_application_event.event_name,
        :template => conversion_application_event.notice_template
    }}

  let(:application_event){ double("ApplicationEventKind",{
                          :name =>'Group Renewal Available',
                          :notice_template => 'notices/shop_employer_notices/5_employer_renewal_notice',
                          :notice_builder => 'ShopEmployerNotices::EmployerRenewalNotice',
                          :event_name => 'group_renewal_5',
                          :mpi_indicator => 'SHOP_D004',
                          :title => "Group Renewal Available"})
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
        expect{ShopEmployerNotices::EmployerRenewalNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::EmployerRenewalNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalNotice.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "append data" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalNotice.new(employer_profile, valid_parmas)
    end
    it "should append data" do
      renewing_plan_year = employer_profile.plan_years.where(:aasm_state => "renewing_draft").first
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.start_on).to eq renewing_plan_year.start_on
      expect(@employer_notice.notice.plan_year.open_enrollment_end_on).to eq renewing_plan_year.open_enrollment_end_on
      expect(@employer_notice.notice.plan_year.carrier_name).to eq renewing_plan_year.benefit_groups.first.reference_plan.carrier_profile.legal_name
    end
  end

  describe "render template and generate pdf for group_renewal_5 notice" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalNotice.new(employer_profile, valid_parmas)
      @employer_notice.build
      @employer_notice.append_data
      @employer_notice.generate_pdf_notice
    end

    it "should render 5_employer_renewal_notice template" do
      expect(@employer_notice.template).to eq "notices/shop_employer_notices/5_employer_renewal_notice"
    end

    it "should generate pdf" do
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

  describe "render template and generate pdf for conversion_group_renewal notice" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::EmployerRenewalNotice.new(employer_profile, conversion_valid_parmas)
      @employer_notice.build
      @employer_notice.append_data
      @employer_notice.generate_pdf_notice
    end

    it "should render 6_conversion_group_renewal_notice template" do
      expect(@employer_notice.template).to eq "notices/shop_employer_notices/6_conversion_group_renewal_notice"
    end

    it "should generate pdf" do
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end