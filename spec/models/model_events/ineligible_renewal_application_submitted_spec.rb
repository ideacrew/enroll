require 'rails_helper'

describe 'ModelEvents::IneligibleRenewalApplicationSubmitted', dbclean: :around_each do

  let(:open_enrollment_end_on) { TimeKeeper.date_of_record + 11.days}
  let!(:employer_profile)       { FactoryGirl.create(:employer_profile) }
  let!(:model_instance) { FactoryGirl.create(:next_month_plan_year, :with_benefit_group, employer_profile: employer_profile, 
    start_on: open_enrollment_end_on.next_month.beginning_of_month,
    open_enrollment_start_on: open_enrollment_end_on - 10.days,
    open_enrollment_end_on: open_enrollment_end_on,
    aasm_state: 'renewing_draft') }
  let!(:benefit_group)  { model_instance.benefit_groups.first }
  let!(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id, benefit_group_assignments: [benefit_group_assignment]) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person) }
  
  before do
    allow(model_instance).to receive(:application_eligibility_warnings).and_return({:primary_office_location => "primary business address not located in #{Settings.aca.state_name}"})
  end

  describe "when renewal employer application is published" do
    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :ineligible_renewal_application_submitted, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.force_publish!
      end
    end

    context "NoticeTrigger" do
      subject { Observers::NoticeObserver.new }

       let(:model_event) { ModelEvents::ModelEvent.new(:ineligible_renewal_application_submitted, model_instance, {}) }

       it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_renewal_eligibility_denial_notice"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.termination_of_employers_health_coverage"
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.plan_year_update(model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    context "when notice event employer_renewal_eligibility_denial_notice is received" do

      let(:data_elements) {
        [
          "employer_profile.notice_date",
          "employer_profile.employer_name",
          "employer_profile.plan_year.warnings"
        ]
      }
      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "PlanYear",
          "event_object_id" => model_instance.id
      } }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return renewal plan year warnings" do
        expect(merge_model.plan_year.warnings).to eq model_instance.application_eligibility_warnings[:primary_office_location]
      end
    end

    context "when notice event termination_of_employers_health_coverage is received" do
    
      let(:data_elements) {
        [
          "employee_profile.notice_date",
          "employee_profile.employer_name",
          "employee_profile.plan_year.warnings",
          "employee_profile.plan_year.renewal_py_end_on",
          "employee_profile.plan_year.py_plus_60_days",
          "employee_profile.ivl_oe_start_date",
          "employee_profile.ivl_oe_end_date"
        ]
      }
      let(:merge_model) { subject.construct_notice_object }
      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "PlanYear",
          "event_object_id" => model_instance.id
      } }

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.force_publish!
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employer name" do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it "should return renewal plan year warnings" do
        expect(merge_model.plan_year.warnings).to eq model_instance.application_eligibility_warnings[:primary_office_location]
      end

      it "should return renewal plan_year end_on" do
        expect(merge_model.plan_year.renewal_py_end_on).to eq model_instance.end_on
      end

      it "should return renewal group termination date + 60 days" do
        expect(merge_model.plan_year.py_plus_60_days).to eq (model_instance.end_on + 60.days).strftime('%m/%d/%Y')
      end

      it "should return IVL OE start date" do
        expect(merge_model.ivl_oe_start_date).to eq Settings.aca.individual_market.upcoming_open_enrollment.start_on
      end

      it "should return IVL OE end date" do
        expect(merge_model.ivl_oe_end_date).to eq Settings.aca.individual_market.upcoming_open_enrollment.end_on
      end
    end
  end
end
