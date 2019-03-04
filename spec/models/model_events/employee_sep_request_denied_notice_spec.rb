require 'rails_helper'

RSpec.describe 'ModelEvents::EmployeeSepRequestDeniedNotice', :dbclean => :after_each do
  let(:organization) { FactoryGirl.create(:organization, :with_active_plan_year) }
  let(:employer_profile) { organization.employer_profile }
  let(:plan_year) { employer_profile.plan_years.first }
  let(:person){ FactoryGirl.create(:person, :with_family)}
  let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person, census_employee_id: census_employee.id) }
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date, market_kind: "shop") }
  let(:notice_event1) {"sep_denial_notice_for_ee_active_on_single_roster"}
  let(:notice_event2) {"sep_denial_notice_for_ee_active_on_multiple_rosters"}

  before do
    today = TimeKeeper.date_of_record.strftime("%m/%d/%Y")
    @qle_date = TimeKeeper.date_of_record.next_month.strftime("%m/%d/%Y")
    @reporting_deadline = @qle_date > today ? today : @qle_date + 30.days
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe "NoticeTrigger when employee is active on single roster" do
    context "when employee sep is denied" do
      subject { Services::NoticeService.new }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload| 
          expect(event_name).to eq "acapi.info.events.employee.sep_denial_notice_for_ee_active_on_single_roster"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.deliver(recipient: person.active_employee_roles.first, event_object: employer_profile.plan_years.first, notice_event: notice_event1, notice_params: {:qle_title=> qle.title, :qle_reporting_deadline=> @reporting_deadline, :qle_event_on=> @qle_date})
      end
    end
  end

  describe "NoticeTrigger when employee is active on single roster" do
    context "when employee sep is denied" do
      subject { Services::NoticeService.new }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload| 
          expect(event_name).to eq "acapi.info.events.employee.sep_denial_notice_for_ee_active_on_multiple_rosters"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.deliver(recipient: person.active_employee_roles.first, event_object: employer_profile.plan_years.first, notice_event: notice_event2, notice_params: {:qle_title=> qle.title, :qle_reporting_deadline=> @reporting_deadline, :qle_event_on=> @qle_date})
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.broker_present?",
        "employee_profile.special_enrollment_period.title",
        "employee_profile.special_enrollment_period.reporting_deadline",
        "employee_profile.special_enrollment_period.event_on",
        "employee_profile.special_enrollment_period.qle_reported_on",
      ]
    }

    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => plan_year.id,
        "notice_params" => {  "qle_title" => qle.title, 
                              "qle_reporting_deadline" => @reporting_deadline, 
                              "qle_event_on" => @qle_date
                            }
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employee first name " do
      expect(merge_model.first_name).to eq person.first_name
    end

    it "should return employee last name " do
      expect(merge_model.last_name).to eq person.last_name
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end

    context "with QLE data_elements" do
      it "should return qle_title" do
        expect(merge_model.special_enrollment_period.title).to eq qle.title
      end

      it "should return qle_reporting_deadline" do
        expect(merge_model.special_enrollment_period.reporting_deadline).to eq  @reporting_deadline
      end

      it "should return event_on" do
        expect(merge_model.special_enrollment_period.event_on).to eq @qle_date
      end

      it "should return qle_reported_on" do
        expect(merge_model.special_enrollment_period.qle_reported_on).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end
    end
  end
end