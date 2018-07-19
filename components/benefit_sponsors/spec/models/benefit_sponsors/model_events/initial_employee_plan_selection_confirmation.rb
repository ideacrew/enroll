require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployeePlanSelectionConfirmation', dbclean: :around_each  do
  let(:model_event)  { "initial_employee_plan_selection_confirmation" }
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month }

  let(:user)    { FactoryGirl.create(:user, :person => person)}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:model_instance)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { model_instance.add_benefit_sponsorship }

  let(:person)       { FactoryGirl.create(:person, :with_family, :with_employee_role) }
  let(:family)       { person.primary_family }
  let!(:benefit_group)    { FactoryGirl.create(:benefit_group) }
  let(:employee_role)     { person.employee_roles.first }
  let!(:hbx_enrollment)   { FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, household: family.active_household, aasm_state: "coverage_enrolled", benefit_group_id: benefit_group.id, employee_role_id: employee_role.id) }
  let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: model_instance, first_name: person.first_name, last_name: person.last_name ) }
    
  describe "NoticeTrigger" do
    context "when ER made binder payment " do
      subject { BenefitSponsors::Observers::BenefitSponsorshipObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.initial_employee_plan_selection_confirmation"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end
         subject.notifier.deliver(recipient: employee_role, event_object: hbx_enrollment, notice_event: "initial_employee_plan_selection_confirmation")
      end
    end
  end

   describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.enrollment.coverage_start_on",
        "employee_profile.enrollment.plan_name",
        "employee_profile.enrollment.employee_responsible_amount",
        "employee_profile.enrollment.employer_responsible_amount",
      ]
    }
    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "EmployerProfile",
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
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.coverage_start_on).to eq hbx_enrollment.effective_on.strftime('%m/%d/%Y')
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.plan_name).to eq hbx_enrollment.product.name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.employer_responsible_amount).to eq hbx_enrollment.employee_responsible_amount
    end

    it "should return employer name" do
      expect(merge_model.enrollment.employer_responsible_amount).to eq model_instance.employer_responsible_amount
    end
  end
end