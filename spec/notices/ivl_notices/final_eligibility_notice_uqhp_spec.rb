require 'rails_helper'
require 'csv'

RSpec.describe IvlNotices::FinalEligibilityNoticeUqhp, :dbclean => :after_each do

  file = "#{Rails.root}/spec/test_data/notices/final_eligibility_notice_uqhp_test_data.csv"
  csv = CSV.open(file,"r",:headers =>true)
  data = csv.to_a
  year = TimeKeeper.date_of_record.year + 1
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :hbx_id => "48574857")}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:plan) { FactoryGirl.create(:plan, :with_premium_tables, market: 'individual', metal_level: 'gold', csr_variant_id: '01', active_year: year, hios_id: "11111111122302-01") }
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual", plan: plan, aasm_state: "auto_renewing", effective_on: Date.new(year,1,1))}
  let!(:hbx_enrollment_member) {FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let!(:hbx_enrollment_member_1) {FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment_1, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let!(:hbx_enrollment_1) {FactoryGirl.create(:hbx_enrollment, household: family.households.first, kind: "individual", plan: plan, is_any_enrollment_member_outstanding: true, aasm_state: "coverage_selected", special_verification_period: TimeKeeper.date_of_record+95.days, effective_on: Date.new(2017,1,1))}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Final Eligibility Notice for UQHP individuals',
                            :notice_template => 'notices/ivl/final_eligibility_notice_uqhp',
                            :notice_builder => 'IvlNotices::FinalEligibilityNoticeUqhp',
                            :event_name => 'final_eligibility_notice_uqhp',
                            :mpi_indicator => 'IVL_FEL',
                            :data => data,
                            :person =>  person,
                            :title => "Your Final Eligibility Results, Plan, And Option TO Change Plans"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :data => data,
      :person => person
  }}

  before do
    allow(person.consumer_role).to receive("person").and_return(person)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::FinalEligibilityNoticeUqhp.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::FinalEligibilityNoticeUqhp.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "#pick_enrollments" do
    before do
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeUqhp.new(person.consumer_role, valid_params)
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      @final_eligibility_notice.append_data
    end

    it "returns all auto_renewing enrollments" do
      @final_eligibility_notice.pick_enrollments
      expect(@final_eligibility_notice.notice.enrollments.size).to eq 1
    end

    it "returns nil when there are no auto_renewing enrollments" do
      hbx_enrollment.update_attributes!(:aasm_state => "coverage_expired")
      @final_eligibility_notice.pick_enrollments
      expect(@final_eligibility_notice.notice.enrollments.size).to eq 0
    end
  end


  describe "#append_data" do
    before do
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeUqhp.new(person.consumer_role, valid_params)
      @final_eligibility_notice.append_data
    end

    it "should return coverage year" do
      expect(@final_eligibility_notice.notice.coverage_year).to eq hbx_enrollment.effective_on.year.to_s
    end
    it "should return notification type" do
      expect(@final_eligibility_notice.notice.notification_type).to eq application_event.event_name
    end
    it "should return ivl open enrollment start on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_start_on).to eq Settings.aca.individual_market.open_enrollment.start_on
    end
    it "should return ivl open enrollment end on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_end_on).to eq Settings.aca.individual_market.open_enrollment.end_on
    end
    it "should return person first name" do
      expect(@final_eligibility_notice.notice.primary_firstname).to eq person.first_name
    end
  end

  describe "#generate_pdf_notice" do
    before do
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeUqhp.new(person.consumer_role, valid_params)
    end

    it "should render the final eligibility notice template" do
      expect(@final_eligibility_notice.template).to eq "notices/ivl/final_eligibility_notice_uqhp"
    end

    it "should generate pdf" do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      @final_eligibility_notice.build
      file = @final_eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

  describe "for recipient, recipient_document_store", dbclean: :after_each do
    let!(:person100)          { FactoryGirl.create(:person, :with_consumer_role, :with_work_email) }
    let!(:dep_family1)        { FactoryGirl.create(:family, :with_primary_family_member, person: FactoryGirl.create(:person, :with_consumer_role, :with_work_email)) }
    let!(:dep_family_member)  { FactoryGirl.create(:family_member, family: dep_family1, person: person100) }
    let!(:family100)          { FactoryGirl.create(:family, :with_primary_family_member, person: person100) }
    let(:dep_fam_primary)     { dep_family1.primary_applicant.person }

    before :each do
      valid_params.merge!({:person => person100})
      @notice = IvlNotices::FinalEligibilityNoticeUqhp.new(person100.consumer_role, valid_params)
    end

    it "should have person100 as the recipient for the enrollment notice as this person is the primary" do
      expect(@notice.recipient).to eq person100
      expect(@notice.person).to eq person100
      expect(@notice.recipient_document_store).to eq person100
      expect(@notice.to).to eq person100.work_email_or_best
    end

    it "should not pick the dep_family1's primary person" do
      expect(@notice.recipient).not_to eq dep_fam_primary
      expect(@notice.person).not_to eq dep_fam_primary
      expect(@notice.recipient_document_store).not_to eq dep_fam_primary
      expect(@notice.to).not_to eq dep_fam_primary.work_email_or_best
    end
  end
end