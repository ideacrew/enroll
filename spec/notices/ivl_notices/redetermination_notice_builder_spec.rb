require 'rails_helper'

RSpec.describe IvlNotices::RedeterminationNoticeBuilder do
  let!(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_work_email)}
  let!(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let!(:family_member2) { FactoryGirl.create(:family_member, family: family)}
  let!(:hbx_enrollment) {FactoryGirl.create(:hbx_enrollment, created_at: (TimeKeeper.date_of_record.in_time_zone("Eastern Time (US & Canada)") - 2.days), household: family.households.first, kind: "individual", aasm_state: "enrolled_contingent", terminated_on: TimeKeeper.date_of_record + 1.day)}
  let!(:hbx_enrollment_member1) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let!(:hbx_enrollment_member2) {FactoryGirl.create(:hbx_enrollment_member,hbx_enrollment: hbx_enrollment, applicant_id: family.family_members.second.id, is_subscriber: false, eligibility_date: TimeKeeper.date_of_record.prev_month )}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'Redetermination Notice',
                            :notice_template => 'notices/ivl/redetermination_notice',
                            :notice_builder => 'IvlNotices::RedeterminationNoticeBuilder',
                            :event_name => 'redetermination_notice',
                            :mpi_indicator => 'IVL_REU',
                            :title => "IMPORTANT NOTICE – CHANGE IN HEALTH COVERAGE ELIGIBILITY"})
                          }
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
      }}

  describe "New" do

    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::RedeterminationNoticeBuilder.new(person.consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::RedeterminationNoticeBuilder.new(person.consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @redetermination_notice = IvlNotices::RedeterminationNoticeBuilder.new(person.consumer_role, valid_parmas)
    end

    it "should build notice with all necessory info" do
      @redetermination_notice.build
      expect(@redetermination_notice.notice.primary_person_age.to_i).to eq person.age_on(TimeKeeper.date_of_record)
      expect(@redetermination_notice.notice.mpi_indicator).to eq application_event.mpi_indicator
      expect(@redetermination_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@redetermination_notice.notice.primary_firstname).to eq person.first_name.titleize
      expect(@redetermination_notice.notice.primary_lastname).to eq person.last_name.titleize
    end
  end

  describe "append_family_members(person)" do
      before do
        @redetermination_notice = IvlNotices::RedeterminationNoticeBuilder.new(person.consumer_role, valid_parmas)
      end

      it "append ivl first_name" do
        people = @redetermination_notice.append_family_members(person)
        expect(people.first.first_name).to eq person.first_name
      end

      it "append ivl last_name" do
        people = @redetermination_notice.append_family_members(person)
        expect(people.first.last_name).to eq person.last_name
      end

      it "append ivl age" do
        people = @redetermination_notice.append_family_members(person)
        expect(people.first.age_on(TimeKeeper.date_of_record)).to eq person.age_on(TimeKeeper.date_of_record)
      end
  end

  describe "#generate_pdf_notice" do
    before do
      @redetermination_notice = IvlNotices::RedeterminationNoticeBuilder.new(person.consumer_role, valid_parmas)
    end
 
    it "should render the final eligibility notice template" do
      expect(@redetermination_notice.template).to eq "notices/ivl/redetermination_notice"
    end
 
    it "should generate pdf" do
      @redetermination_notice.build
      @redetermination_notice.append_hbe
      @redetermination_notice.append_family_members(person)
      file = @redetermination_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end
