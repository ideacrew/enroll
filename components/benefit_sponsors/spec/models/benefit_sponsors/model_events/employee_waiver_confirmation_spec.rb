require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::EmployeeWaiverConfirmation', dbclean: :around_each  do

  let(:model_event)  { "employee_waiver_confirmation" }
  
  let(:start_on) {  (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:current_effective_date)  { TimeKeeper.date_of_record }

  let(:person)       { FactoryGirl.create(:person, :with_family) }
  let(:family)       { person.primary_family }
  let!(:benefit_group)    { FactoryGirl.create(:benefit_group) }
  let!(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: employer_profile, census_employee_id: census_employee.id)}
  let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name ) }

  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
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
  let!(:model_instance) { 
    hbx_enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                        household: family.active_household, 
                        aasm_state: "coverage_selected",
                        effective_on: benefit_application.start_on,
                        kind: "employer_sponsored",
                        rating_area_id: benefit_application.recorded_rating_area_id,
                        sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                        benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                        employee_role_id: employee_role.id) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }

  describe "ModelEvent", dbclean: :around_each  do
    context "when employee waives coverage" do
      it "should trigger model event" do
        model_instance.class.observer_peers.keys.each do |observer|
          expect(observer).to receive(:notifications_send) do |model_instance, model_event|
            expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :employee_waiver_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.waive_coverage!
      end
    end
  end

  describe "NoticeTrigger", dbclean: :around_each  do
    context "when employee waives coverage" do
      subject { BenefitSponsors::Observers::HbxEnrollmentObserver.new  }
      let(:model_event) { BenefitSponsors::ModelEvents::ModelEvent.new(:employee_waiver_confirmation, model_instance, {}) }

      it "should trigger notice event" do
        allow(model_instance).to receive(:is_shop?).and_return(true)
        allow(model_instance).to receive(:census_employee).and_return(census_employee)
        allow(census_employee).to receive(:employee_role).and_return(employee_role)
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employee.employee_waiver_confirmation"
          expect(payload[:employee_role_id]).to eq model_instance.employee_role.id.to_s
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.notifications_send(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employee_profile.notice_date",
        "employee_profile.employer_name",
        "employee_profile.broker.primary_fullname",
        "employee_profile.broker.organization",
        "employee_profile.broker.phone",
        "employee_profile.broker.email",
        "employee_profile.broker_present?"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
    let!(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let!(:payload)   { {
      "event_object_kind" => "HbxEnrollment",
      "event_object_id" => model_instance.id
    } }
    let(:merge_model) { subject.construct_notice_object }
    let(:benefit_group_assignment) { double(hbx_enrollment: model_instance, active_hbx_enrollments: [model_instance]) }


    context "when notice event received" do
      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
      end
      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      it "should retrun merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return the date of the notice" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return false when there is no broker linked to employer" do
        expect(merge_model.broker_present?).to be_falsey
      end

      it "should return waived effective on date" do
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
        allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([model_instance])
        waived_on = census_employee.active_benefit_group_assignment.hbx_enrollments.first.updated_at
        expect(waived_on).to eq model_instance.updated_at
      end
    end
  end
end

