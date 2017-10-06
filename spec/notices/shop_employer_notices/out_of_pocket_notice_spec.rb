require 'rails_helper'

RSpec.describe ShopEmployerNotices::OutOfPocketNotice do
  let(:employer_profile){ create :employer_profile}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ create :person}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Out of pocket Notice',
                            :notice_template => 'notices/shop_employer_notices/out_of_pocket_notice',
                            :notice_builder => 'ShopEmployerNotices::OutOfPocketNotice',
                            :event_name => 'out_of_pocker_url_notifier',
                            :mpi_indicator => 'SHOP_D087',
                            :title => "Plan Match Health Plan Comparison Tool – Instructions for Your Employees"})
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
        expect{ShopEmployerNotices::OutOfPocketNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::OutOfPocketNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @oop_notice = ShopEmployerNotices::OutOfPocketNotice.new(employer_profile, valid_parmas)
      @oop_notice.build
    end
    it "should return employer staff name" do
      expect(@oop_notice.notice.employer_name).to eq employer_profile.organization.legal_name
      expect(@oop_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
    it "should return employer legal name" do
      expect(@oop_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
    it "should return employer hbx_id" do
      expect(@oop_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

  describe "#generate_pdf_notice" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @oop_notice = ShopEmployerNotices::OutOfPocketNotice.new(employer_profile, valid_parmas)
      @oop_notice.build
      @oop_notice.append_data
    end

    it "should render the projected eligibility notice template" do
      expect(@oop_notice.template).to eq "notices/shop_employer_notices/out_of_pocket_notice"
    end

    it "should generate pdf" do
      file = @oop_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end


end