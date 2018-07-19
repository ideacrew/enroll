require 'rails_helper'

module BenefitSponsors
  RSpec.describe 'ModelEvents::NotifyEmployeeOfPlanSelectionInOpenEnrollment', dbclean: :around_each  do
    let(:model_event)  { "notify_employee_of_plan_selection_in_open_enrollment" }
    let(:person)       { FactoryGirl.create(:person, :with_family, :with_employee_role) }
    let(:family)       { person.primary_family }
    let!(:benefit_group)    { FactoryGirl.create(:benefit_group) }
    let(:employee_role)     { person.employee_roles.first }
    let!(:model_instance)   { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, household: family.active_household, aasm_state: "coverage_enrolled", benefit_group_id: benefit_group.id, employee_role_id: employee_role.id) }
    let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name ) }
    
    let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)     { organization.employer_profile }
    let!(:rating_area)         { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)        { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let(:benefit_sponsorship)  { employer_profile.add_benefit_sponsorship }

    describe "NoticeTrigger" do
      context "when employee terminates coverage" do
        subject { BenefitSponsors::Observers::HbxEnrollmentObserver.new }
        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_plan_selection_in_open_enrollment"
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
          subject.notifier.deliver(recipient: employee_role, event_object: model_instance, notice_event: "notify_employee_of_plan_selection_in_open_enrollment")
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
            "employee_profile.enrollment.coverage_end_on",
            "employee_profile.enrollment.coverage_kind",
            "employee_profile.enrollment.plan_name"
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
        employee_role.update_attributes(census_employee_id: census_employee.id) 
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice_date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employee first_name" do
        expect(merge_model.first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.last_name).to eq model_instance.census_employee.last_name
      end

      it "should return employer legal_name" do
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
      end

      it "should return plan name" do
        expect(merge_model.enrollment.plan_name).to eq model_instance.product.name
      end
    end
  end
end