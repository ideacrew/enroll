require 'rails_helper'

RSpec.describe IvlNotices::ConsumerNotice, :dbclean => :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role)}
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, :min_verification_due_date => TimeKeeper.date_of_record+95.days) }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year}
  let(:hbx_enrollment_member){ FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, hbx_enrollment_members: [hbx_enrollment_member], household: family.active_household, kind: "individual", aasm_state: "enrolled_contingent")}
  let(:plan){ FactoryGirl.create(:plan) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'First Outstanding Verification Notification',
                            :notice_template => 'notices/ivl/documents_verification_reminder',
                            :notice_builder => 'IvlNotices::ConsumerNotice',
                            :mpi_indicator => 'MPI_IVLV20A',
                            :event_name => 'first_verifications_reminder',
                            :title => "First Outstanding Verification Notification"})
                          }
    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

  describe "New" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      @consumer_role = IvlNotices::ConsumerNotice.new(person.consumer_role, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        @consumer_role = IvlNotices::ConsumerNotice.new(person.consumer_role, valid_parmas)
        expect{IvlNotices::ConsumerNotice.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::ConsumerNotice.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      allow(person).to receive("primary_family").and_return(family)
      @consumer_notice = IvlNotices::ConsumerNotice.new(person.consumer_role, valid_parmas)
    end
    it "should build notice with all necessory info" do
      expect(@consumer_notice).to receive("append_unverified_family_members").and_return(true)
      @consumer_notice.build
      expect(@consumer_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
  end

  describe "#generate_pdf_notice" do
    before do
      person.consumer_role.update_attributes!(:aasm_state => "verification_outstanding")
      allow(hbx_enrollment).to receive("plan").and_return(plan)
      allow(person).to receive("primary_family").and_return(family)
      @consumer_notice = IvlNotices::ConsumerNotice.new(person.consumer_role, valid_parmas)
    end

    it "should render the projected eligibility notice template" do
      expect(@consumer_notice.template).to eq "notices/ivl/documents_verification_reminder"
    end

    it "should generate pdf" do
      @consumer_notice.build
      file = @consumer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end