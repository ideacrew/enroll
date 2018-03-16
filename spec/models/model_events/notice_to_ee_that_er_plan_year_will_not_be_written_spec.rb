require 'rails_helper'

describe 'ModelEvents::InitialEmployerNoBinderPaymentReceived', :dbclean => :after_each do

  let(:model_event) { "initial_employer_no_binder_payment_received" }
  let(:notice_event) { "notice_to_ee_that_er_plan_year_will_not_be_written" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:employer_profile){ FactoryGirl.create(:employer_profile)}
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolled' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
  let!(:date_mock_object) { model_instance.class.calculate_open_enrollment_date(start_on)[:binder_payment_due_date].next_day }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
  end

  describe "ModelEvent" do
    context "when initial employer missed binder payment deadline" do
      it "should trigger model event" do
        expect_any_instance_of(Observers::Observer).to receive(:trigger_notice).with(recipient: employee_role, event_object: model_instance, notice_event: notice_event).and_return(true)
        PlanYear.date_change_event(date_mock_object)
      end
    end
  end

  describe "NoticeTrigger" do
    context "whne binder payment is missed" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_no_binder_payment_received, PlanYear, {}) }

      it "should trigger notice for employees" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.notice_to_ee_that_er_plan_year_will_not_be_written"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
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
          "employee_profile.plan_year.current_py_start_date",
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
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(employee_role)
      allow(subject).to receive(:payload).and_return(payload)
      PlanYear.date_change_event(date_mock_object)
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return plan year start date" do
      expect(merge_model.plan_year.current_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
    end

    it "should return broker" do
      expect(merge_model.broker_present?).to be_falsey
    end
  end
end

