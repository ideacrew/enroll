require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::EmployeeCoverageTermination', dbclean: :after_each  do
  let(:notice_event) { "employer_notice_for_employee_coverage_termination" }

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

  let(:person)       { FactoryGirl.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let!(:benefit_group)    { FactoryGirl.create(:benefit_group) }
  let!(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile)}
  let!(:model_instance)   { hbx_enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                                                                household: family.active_household, 
                                                                aasm_state: "coverage_enrolled", 
                                                                benefit_group_id: benefit_group.id, 
                                                                employee_role_id: employee_role.id,
                                                                ) 
                            hbx_enrollment.benefit_sponsorship = benefit_sponsorship
                            hbx_enrollment.save!
                            hbx_enrollment
  }
  let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name ) }
    
  describe "NoticeTrigger" do
    context "when employee terminates coverage" do
      subject { BenefitSponsors::Observers::HbxEnrollmentObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:employee_coverage_termination, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employer_notice_for_employee_coverage_termination"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.notifier.deliver(recipient: model_instance.employer_profile, event_object: model_instance, notice_event: notice_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "employer_profile.notice_date",
          "employer_profile.first_name",
          "employer_profile.last_name",
          "employer_profile.employer_name",
          "employer_profile.enrollment.coverage_end_on",
          "employer_profile.enrollment.enrolled_count",
          "employer_profile.enrollment.employee_first_name",
          "employer_profile.enrollment.employee_last_name",
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
      employee_role.update_attributes(census_employee_id: census_employee.id) 
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

    it "should return enrollment terminated_on date " do
      expect(merge_model.enrollment.coverage_end_on).to eq model_instance.terminated_on
    end

    it "should return enrollment coverage_kind" do
      expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
    end

    it "should return enrollment covered dependents" do
      expect(merge_model.enrollment.enrolled_count).to eq model_instance.humanized_dependent_summary.to_s
    end

  end
end
