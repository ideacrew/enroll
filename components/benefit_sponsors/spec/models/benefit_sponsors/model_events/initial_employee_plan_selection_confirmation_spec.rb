require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::InitialEmployeePlanSelectionConfirmation', dbclean: :around_each  do
  let(:model_event)  { "initial_employee_plan_selection_confirmation" }
  let!(:start_on) { TimeKeeper.date_of_record.beginning_of_month }
  let(:current_effective_date)  { TimeKeeper.date_of_record }

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:employer_profile)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:benefit_market_catalog) { create(:benefit_markets_benefit_market_catalog, :with_product_packages,
                                  benefit_market: benefit_market,
                                  title: "SHOP Benefits for #{current_effective_date.year}",
                                  application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
                                }
  let!(:benefit_application) {
    application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, 
      aasm_state: "enrollment_eligible", 
      benefit_sponsorship: benefit_sponsorship
      )
    application.benefit_sponsor_catalog.save!
    application
  }

  let(:user)    { FactoryGirl.create(:user, :person => person)}
  let(:person)       { FactoryGirl.create(:person, :with_family, :with_employee_role) }
  let(:family)       { person.primary_family }
  let(:employee_role)     { FactoryGirl.create(:benefit_sponsors_employee_role, employer_profile: employer_profile, person: person) }
  let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, 
    benefit_sponsorship: benefit_sponsorship, 
    employer_profile_id: employer_profile.id,
    first_name: person.first_name, 
    last_name: person.last_name,
    employee_role_id: employee_role.id
    ) 
  }
  let!(:benefit_group)    { benefit_application.benefit_groups.last }
  let!(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }

  let!(:hbx_enrollment) { 
    hbx_enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        aasm_state: "shopping",
                        effective_on: benefit_application.start_on,
                        rating_area_id: benefit_application.recorded_rating_area_id,
                        sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                        benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                        employee_role_id: employee_role.id,
                        benefit_group_assignment_id: benefit_group_assignment.id ) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  before do
    employee_role.update_attributes(census_employee_id: census_employee.id)
    benefit_group_assignment.update_attributes(hbx_enrollment_id: hbx_enrollment.id, benefit_group_id: benefit_group.id)
  end

  describe "Plan selection confirmation when ER made binder payment" do
    # context "ModelEvent" do
    #   it "should trigger model event" do
    #     hbx_enrollment.class.observer_peers.keys.each do |observer|
    #       expect(observer).to receive(:notifications_send) do |instance, model_event|
    #         expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
    #         expect(model_event).to have_attributes(:event_key => :application_coverage_selected, :klass_instance => hbx_enrollment, :options => {})
    #       end
    #     end
    #     hbx_enrollment.select_coverage!
    #   end
    # end

    context "NoticeTrigger" do
      subject { BenefitSponsors::Observers::BenefitSponsorshipObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:initial_employee_plan_selection_confirmation, benefit_sponsorship, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.initial_employee_plan_selection_confirmation"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq hbx_enrollment.id.to_s
        end
        subject.notifications_send(hbx_enrollment, model_event)
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
        "event_object_kind" => "HbxEnrollment",
        "event_object_id" => hbx_enrollment.id
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

    it "should return notice_date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer_name" do
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.coverage_start_on).to eq hbx_enrollment.effective_on.strftime('%m/%d/%Y')
    end

    it "should return plan_name " do
      expect(merge_model.enrollment.plan_name).to eq hbx_enrollment.product.name
    end

    it "should return employee_responsible_amount" do
      expect(merge_model.enrollment.employer_responsible_amount.to_f).to eq hbx_enrollment.total_employee_cost
    end

    it "should return employer_responsible_amount" do
      expect(merge_model.enrollment.employer_responsible_amount.to_f).to eq hbx_enrollment.total_employer_contribution
    end
  end
end