require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::GenerateInitialEmployerInvoice', dbclean: :after_each do

  let(:model_event) { "generate_initial_employer_invoice" }
  let(:notice_event) { "generate_initial_employer_invoice" }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:site_key) { EnrollRegistry[:enroll_app].setting(:site_key).item.downcase }
  let!(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, site_key) }
  let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{site_key}_employer_profile".to_sym, site: site) }
  let!(:model_instance)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { model_instance.add_benefit_sponsorship }
  let!(:benefit_application) { FactoryBot.create(:benefit_sponsors_benefit_application,
    :with_benefit_package,
    :benefit_sponsorship => benefit_sponsorship,
    :aasm_state => 'enrollment_eligible',
    :effective_period =>  start_on..(start_on + 1.year) - 1.day
  )}

  let(:person)                  { FactoryBot.create(:person, :with_family) }
  let(:family)                  { person.primary_family }
  let!(:census_employee) do
    create(
      :benefit_sponsors_census_employee,
      benefit_sponsorship: benefit_sponsorship,
      employer_profile: model_instance,
      first_name: person.first_name,
      last_name: person.last_name,
      benefit_group_assignments: [benefit_group_assignment]
    )
  end
  let(:benefit_group_assignment) { build(:benefit_group_assignment, benefit_group: benefit_application.benefit_packages[0]) }

  let!(:employee_role)          { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: model_instance, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: model_instance.id)}
  let!(:hbx_enrollment) do
    create(
      :hbx_enrollment, :with_enrollment_members, :with_product,
      household: family.active_household,
      family: family,
      aasm_state: "coverage_selected",
      effective_on: benefit_application.start_on,
      submitted_at: benefit_application.open_enrollment_period.max,
      rating_area_id: benefit_application.recorded_rating_area_id,
      sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
      sponsored_benefit_package_id: benefit_application.benefit_packages.first.id,
      benefit_sponsorship_id: benefit_application.benefit_sponsorship.id,
      eligible_child_care_subsidy: eligible_child_care_subsidy,
      employee_role_id: employee_role.id,
      hbx_enrollment_members: [hbx_enrollment_member]
    )
  end
  let(:eligible_child_care_subsidy) { 150.0 }

  let!(:hbx_enrollment_member) do
    HbxEnrollmentMember.new(
      applicant_id: family.family_members.first.id,
      is_subscriber: true,
      eligibility_date: TimeKeeper.date_of_record.prev_month,
      coverage_start_on: TimeKeeper.date_of_record.prev_month
    )
  end

  before do
    census_employee.update_attributes(employee_role_id: employee_role.id)
    allow(::BenefitMarkets::Products::ProductRateCache).to receive(:lookup_rate).and_return(814.85)
  end

  describe "ModelEvent" do
    it "should trigger model event" do
      model_instance.class.observer_peers.keys.select{ |ob| ob.is_a? BenefitSponsors::Observers::NoticeObserver }.each do |observer|
        expect(observer).to receive(:process_employer_profile_events) do |_instance, model_event|
          expect(model_event).to be_an_instance_of(::BenefitSponsors::ModelEvents::ModelEvent)
          expect(model_event).to have_attributes(:event_key => :generate_initial_employer_invoice, :klass_instance => model_instance, :options => {})
        end
      end
      model_instance.trigger_model_event(:generate_initial_employer_invoice)
    end
  end

  describe "NoticeTrigger" do
    context "when initial invoice is generated" do
      subject { BenefitSponsors::Observers::NoticeObserver.new }
      let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:generate_initial_employer_invoice, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.generate_initial_employer_invoice"
          expect(payload[:employer_id]).to eq model_instance.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::BenefitApplications::BenefitApplication'
          expect(payload[:event_object_id]).to eq benefit_application.id.to_s
        end
        subject.process_employer_profile_events(model_instance, model_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.account_number",
        "employer_profile.invoice_number",
        "employer_profile.invoice_date",
        "employer_profile.coverage_month",
        "employer_profile.date_due",
        "employer_profile.total_eligible_child_care_subsidy",
        "employer_profile.total_amount_due",
        "employer_profile.benefit_application.osse_eligible"
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { "Notifier::MergeDataModels::EmployerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::BenefitApplications::BenefitApplication",
        "event_object_id" => benefit_application.id
    } }

    context "when notice event received" do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(model_instance)
        allow(subject).to receive(:payload).and_return(payload)
        allow(benefit_application).to receive(:osse_eligible?).and_return(true)
        model_instance.trigger_model_event(:generate_initial_employer_invoice)
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return account number" do
        expect(merge_model.account_number).to eq (model_instance.organization.hbx_id)
      end

      it "should return invoice number" do
        expect(merge_model.invoice_number).to eq (model_instance.organization.hbx_id+DateTime.now.next_month.strftime('%m%Y'))
      end

      it "should return invoice date" do
        expect(merge_model.invoice_date).to eq (TimeKeeper.date_of_record.strftime("%m/%d/%Y"))
      end

      it "should return coverage month" do
        expect(merge_model.coverage_month).to eq (TimeKeeper.date_of_record.next_month.strftime("%m/%Y"))
      end

      it "should return due date" do
        schedular = BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        expect(merge_model.date_due).to eq (schedular.calculate_open_enrollment_date(benefit_application.is_renewing? ,TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].strftime("%m/%d/%Y"))
      end

      it "should return osse subsidy" do
        expect(merge_model.total_eligible_child_care_subsidy).to eq("$150.00")
      end

      it "should return total amount due" do
        expect(merge_model.total_amount_due).to eq("$664.85")
      end

      it "should return osse eligibility" do
        expect(merge_model.benefit_application.osse_eligible).to be_truthy
      end
    end
  end
end
