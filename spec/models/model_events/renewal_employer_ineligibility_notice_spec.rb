require 'rails_helper'

describe 'ModelEvents::RenewalEmployerIneligibiltyNotice', dbclean: :around_each do

  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let(:family)  { person.primary_family }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:employer) { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer, first_name: person.first_name, last_name: person.last_name) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on, :aasm_state => 'active' ) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer,census_employee_id: census_employee.id, person: person) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer, start_on: start_on + 1.year, :aasm_state => 'renewing_enrolling', open_enrollment_start_on: TimeKeeper.date_of_record.prev_day - 11.days, open_enrollment_end_on: TimeKeeper.date_of_record.prev_day) }
  let!(:renewal_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: model_instance, title: "Benefits #{model_instance.start_on.year}") }
  let!(:date_mock_object) { (start_on - 2.months).end_of_month.prev_day }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
    household: family.active_household,
    employee_role_id: employee_role.id,
    aasm_state: "shopping",
    benefit_group_id: renewal_benefit_group.id,
    benefit_group_assignment_id: benefit_group_assignment.id )
  }
  before :each do
    person.employee_roles[0].update_attributes(census_employee_id: census_employee.id)
    census_employee.update_attributes(employee_role_id: person.employee_roles[0].id)
  end

  describe "ModelEvent" do

    before do
      allow(employer).to receive_message_chain("staff_roles.first").and_return(person)
    end
    
    after do
     TimeKeeper.set_date_of_record_unprotected!(Date.today)
    end

    context "when renewal employer application is denied" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_application_denied, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.advance_date!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when renewal application denied" do
      subject { Observers::NoticeObserver.new }

      let(:model_event) { ModelEvents::ModelEvent.new(:renewal_application_denied, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.renewal_employer_ineligibility_notice"
          expect(payload[:employer_id]).to eq employer.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_renewal_employer_ineligibility_notice"
          expect(payload[:employee_role_id]).to eq census_employee.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.plan_year.renewal_py_start_date",
        "employer_profile.plan_year.current_py_end_date",
        "employer_profile.plan_year.renewal_py_oe_end_date",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker.email",
        "employer_profile.broker_present?",
        "employer_profile.plan_year.enrollment_errors"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer)
        allow(subject).to receive(:payload).and_return(payload)
        PlanYear.date_change_event(date_mock_object)
      end

      it "should return merge mdoel" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer.legal_name
      end

      it "should return plan year start date" do
        expect(merge_model.plan_year.renewal_py_start_date).to eq model_instance.start_on.strftime('%m/%d/%Y')
      end

      it "should return current plan year end date" do
        expect(merge_model.plan_year.current_py_end_date).to eq plan_year.end_on.strftime('%m/%d/%Y')
      end

      it "should return renewal application open enrollment end date" do
        expect(merge_model.plan_year.renewal_py_oe_end_date).to eq model_instance.open_enrollment_end_on.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

      it "should return enrollment errors" do
        enrollment_errors = []
        model_instance.enrollment_errors.each do |k, v|
          case k.to_s
          when 'eligible_to_enroll_count'
            enrollment_errors << 'at least one employee must be eligible to enroll'
          when 'non_business_owner_enrollment_count'
            enrollment_errors << "at least #{Settings.aca.shop_market.non_owner_participation_count_minimum} non-owner employee must enroll"
          when 'enrollment_ratio'
            unless model_instance.effective_date.yday == 1
              enrollment_errors << "number of eligible participants enrolling (#{model_instance.total_enrolled_count}) is less than minimum required #{model_instance.minimum_enrolled_count}"
            end
          end
        end
        expect(merge_model.plan_year.enrollment_errors).to eq enrollment_errors.join(' AND/OR ')
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.first_name",
        "employee_profile.last_name",
        "employee_profile.employer_name",
        "employee_profile.enrollment.employee_first_name",
        "employee_profile.enrollment.employee_last_name",
        "employee_profile.enrollment.coverage_kind"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "PlanYear",
        "event_object_id" => model_instance.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

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
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return employee first_name" do
        expect(merge_model.first_name).to eq census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.last_name).to eq census_employee.last_name
      end
    end
  end
end
