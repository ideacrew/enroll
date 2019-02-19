require 'rails_helper'

RSpec.describe 'ModelEvents::ApplicationCoverageSelected', dbclean: :around_each  do

  let(:model_event)  { "application_coverage_selected" }
  let!(:person) { FactoryGirl.create(:person, :with_family) }
  let(:family)  { person.primary_family }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year) }
  let!(:organization) { FactoryGirl.create(:organization) }
  let!(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: census_employee) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization) }
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: 'active') }
  let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name) }
  let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, census_employee_id: census_employee.id, person: person) }
  let!(:model_instance) { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members,
    household: family.active_household,
    employee_role_id: employee_role.id, 
    aasm_state: "shopping",
    enrollment_kind: "special_enrollment",
    special_enrollment_period_id: sep.id,
    benefit_group_id: benefit_group.id,
    benefit_group_assignment_id: benefit_group_assignment.id )
  }
  let(:sep) { FactoryGirl.create(:special_enrollment_period, family: family, title: "Married") }

  describe "when an employee selects employer sponsored coverage" do

    let(:subject) { Observers::NoticeObserver.new }
    
    context "ModelEvent" do
      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:hbx_enrollment_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :application_coverage_selected, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.select_coverage!
      end
    end

    context "NoticeTrigger " do
      let(:model_event) { ModelEvents::ModelEvent.new(:application_coverage_selected, model_instance, {}) }

      context 'when EE makes plan selection in open enrollment' do
        before :each do
          allow(model_instance).to receive(:new_hire_enrollment_for_shop?).and_return(false)
          allow(model_instance).to receive(:enrollment_kind).and_return('open_enrollment')
        end

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_plan_selection_in_open_enrollment"
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
          subject.hbx_enrollment_update(model_event)
        end
      end

      context 'when EE makes plan selection in special enrollment' do
        before :each do
          allow(model_instance).to receive(:is_special_enrollment?).and_return(true)
        end

        it "should trigger notice event for plan selection in sep or new_hire" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.employee_plan_selection_confirmation_sep_new_hire"
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end

          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employer.employee_mid_year_plan_change_non_congressional_notice"
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
          subject.hbx_enrollment_update(model_event)
        end
      end
    end
  end

  describe "NoticeBuilder" do

    before do 
      model_instance.select_coverage!
    end

    context "when notice event employee_plan_selection_confirmation_sep_new_hire is triggered" do
      let(:data_elements) {
        [
          "employee_profile.notice_date",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.employer_name",
          "employee_profile.enrollment.coverage_start_on",
          "employee_profile.enrollment.enrolled_count",
          "employee_profile.enrollment.enrollment_kind",
          "employee_profile.enrollment.employee_first_name",
          "employee_profile.enrollment.employee_last_name",
          "employee_profile.enrollment.coverage_kind"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
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
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return employee first_name" do
        expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
      end

      it "should return employee enrollment coverage_start_on" do
        expect(merge_model.enrollment.coverage_start_on).to eq model_instance.effective_on.strftime('%m/%d/%Y')
      end

      it "should return enrollment enrollment_kind" do
        expect(merge_model.enrollment.enrollment_kind).to eq model_instance.enrollment_kind
      end

      it "should return enrollment covered dependents" do
        expect(merge_model.enrollment.enrolled_count).to eq model_instance.humanized_dependent_summary.to_s
      end
    end

    context "when notify_employee_of_plan_selection_in_open_enrollment is triggered" do
      let(:data_elements) {
        [
          "employee_profile.notice_date",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.employer_name",
          "employee_profile.enrollment.coverage_start_on",
          "employee_profile.enrollment.enrolled_count",
          "employee_profile.enrollment.employee_first_name",
          "employee_profile.enrollment.employee_last_name",
          "employee_profile.enrollment.enrollment_kind",
          "employee_profile.enrollment.coverage_kind"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        model_instance.update_attributes(enrollment_kind: "open_enrollment")
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
        expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
      end

      it "should return enrollment coverage_start_on" do
        expect(merge_model.enrollment.coverage_start_on).to eq model_instance.effective_on.strftime('%m/%d/%Y')
      end

      it "should return enrollment enrollment_kind" do
        expect(merge_model.enrollment.enrollment_kind).to eq model_instance.enrollment_kind
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
      end

      it "should return enrollment covered dependents" do
        expect(merge_model.enrollment.enrolled_count).to eq model_instance.humanized_dependent_summary.to_s
      end
    end

    context "when employee mid-year plan change is triggered" do
      let(:data_elements) {
        [
            "employer_profile.notice_date",
            "employer_profile.first_name",
            "employer_profile.last_name",
            "employer_profile.employer_name",
            "employer_profile.enrollment.coverage_start_on",
            "employer_profile.enrollment.employee_first_name",
            "employer_profile.enrollment.employee_last_name",
            "employer_profile.enrollment.enrollment_kind",
            "employer_profile.enrollment.coverage_kind"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
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
        expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
      end

      it "should return enrollment coverage_start_on" do
        expect(merge_model.enrollment.coverage_start_on).to eq model_instance.effective_on.strftime('%m/%d/%Y')
      end

      it "should return enrollment enrollment_kind" do
        expect(merge_model.enrollment.enrollment_kind).to eq model_instance.enrollment_kind
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
      end
    end
  end
end
