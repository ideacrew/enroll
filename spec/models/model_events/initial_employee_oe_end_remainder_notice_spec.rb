require 'rails_helper'

RSpec.describe 'ModelEvents::InitialEmployeeOeEndRemainderNotice', :dbclean => :after_each  do
  let(:notice_event) { "initial_employee_oe_end_reminder_notice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:organization) { FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, aasm_state: 'enrolling') }
  let(:person){ FactoryGirl.create(:person, :with_family)}
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
  let(:date_mock_object) { double("Date", day: (Settings.aca.shop_market.open_enrollment.monthly_end_on - 2))}

  before do
    TimeKeeper.set_date_of_record_unprotected!(Date.new(start_on.year, start_on.prev_month.month, date_mock_object.day))
  end

  after :all do
    TimeKeeper.set_date_of_record_unprotected!(Date.today)
  end
    
  describe "ModelEvent" do
    it "should trigger model event" do
      expect_any_instance_of(Observers::NoticeObserver).to receive(:deliver).with(recipient: employee_role, event_object: plan_year, notice_event: notice_event).and_return(true)
      PlanYear.date_change_event(date_mock_object)
    end
  end

  describe "NoticeTrigger" do
    context "2 days before open enrollment end date" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employee_oe_end_reminder_notice, plan_year, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.initial_employee_oe_end_reminder_notice"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.plan_year_date_change(model_event)
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
        "employee_profile.plan_year.current_py_oe_end_date",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => plan_year.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

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

    it "should return employer name" do
      expect(merge_model.employer_name).to eq census_employee.employer_profile.legal_name
    end

    it "should return employee first name " do
      expect(merge_model.first_name).to eq person.first_name
    end

    it "should return employee last name " do
      expect(merge_model.last_name).to eq person.last_name
    end

    it "" do
      expect(merge_model.plan_year.current_py_oe_end_date).to eq plan_year.open_enrollment_end_on.strftime('%m/%d/%Y')
    end

    it "should return false when there is no broker linked to employer" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end
