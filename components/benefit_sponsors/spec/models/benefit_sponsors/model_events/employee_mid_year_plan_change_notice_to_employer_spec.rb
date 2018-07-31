require 'rails_helper'

RSpec.describe 'ModelEvents::EmployeeMidYearPlanChangeNoticeToEmployer', :dbclean => :after_each do

  let(:model_event)  { "application_coverage_selected" }
  let(:notice_event) { "employee_mid_year_plan_change_notice_to_employer" }
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
                        aasm_state: "shopping",
                        effective_on: benefit_application.start_on,
                        rating_area_id: benefit_application.recorded_rating_area_id,
                        sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                        sponsored_benefit_package_id:benefit_application.benefit_packages.first.id,
                        benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                        employee_role_id: employee_role.id) 
    hbx_enrollment.benefit_sponsorship = benefit_sponsorship
    hbx_enrollment.save!
    hbx_enrollment
  }


  describe "NoticeTrigger" do
    context "when employees made mid-year plan change in their account" do
      subject { Observers::NoticeObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.employee_mid_year_plan_change_notice_to_employer"
          expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.deliver(recipient: employer_profile, event_object: model_instance, notice_event: "employee_mid_year_plan_change_notice_to_employer")
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
        "employer_profile.notice_date",
        "employer_profile.employer_name",
        "employer_profile.enrollment.employee_first_name",
        "employer_profile.enrollment.employee_last_name",
        "employer_profile.enrollment.coverage_start_on",
        "employer_profile.broker.primary_fullname",
        "employer_profile.broker.organization",
        "employer_profile.broker.phone",
        "employer_profile.broker_present?"
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
      expect(merge_model.employer_name).to eq employer_profile.legal_name
    end

    it "should return employee first_name" do
      expect(merge_model.enrollment.employee_first_name).to eq model_instance.census_employee.first_name
    end

    it "should return employee last_name" do
      expect(merge_model.enrollment.employee_last_name).to eq model_instance.census_employee.last_name
    end

    it "should return enrollment effective date " do
      expect(merge_model.enrollment.coverage_start_on).to eq model_instance.effective_on.strftime('%m/%d/%Y')
    end
  end
end