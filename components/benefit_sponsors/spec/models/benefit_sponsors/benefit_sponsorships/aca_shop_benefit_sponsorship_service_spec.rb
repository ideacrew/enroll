require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitSponsorships::AcaShopBenefitSponsorshipService, dbclean: :after_each do

    let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
    let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
    let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
    let!(:service_area) { create_default(:benefit_markets_locations_service_area) }

    let(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let(:benefit_market)  { site.benefit_markets.first }

    let(:employer_organization)   { FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)        { employer_organization.employer_profile }

    let!(:rating_area)                    { FactoryBot.create(:benefit_markets_locations_rating_area)  }
    let!(:service_area)                    { FactoryBot.create(:benefit_markets_locations_service_area)  }
    let(:this_year)                       { TimeKeeper.date_of_record.year }

    let(:april_effective_date)            { Date.new(this_year,4,1) }
    let(:april_open_enrollment_begin_on)  { april_effective_date - 1.month }
    let(:april_open_enrollment_end_on)    { april_open_enrollment_begin_on + 9.days }

    let(:initial_application_state)       { :active }
    let(:renewal_application_state)       { :enrollment_open }

    let(:sponsorship_state)               { :active }
    let(:renewal_sponsorship_state)       { :active }
    let(:renewal_current_application_state) { :active }

    let!(:april_sponsors) do
      create_list(
        :benefit_sponsors_benefit_sponsorship,
        2,
        :with_organization_cca_profile,
        :with_initial_benefit_application,
        initial_application_state: initial_application_state,
        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
        site: site,
        aasm_state: sponsorship_state
      )
    end

    let(:april_renewal_sponsors) do
      create_list(
        :benefit_sponsors_benefit_sponsorship,
        2,
        :with_organization_cca_profile,
        :with_previous_year_rating_area,
        :with_previous_year_service_areas,
        :with_renewal_benefit_application,
        initial_application_state: renewal_current_application_state,
        renewal_application_state: renewal_application_state,
        default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)),
        site: site,
        aasm_state: renewal_sponsorship_state
      )
    end

    let(:current_date)                    { Date.new(this_year,3,14) }

    before { TimeKeeper.set_date_of_record_unprotected!(current_date) }
    subject { BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService }

    # We are not moving benefit applications to ineligible status automatically if binder payment is missed
    # describe '.mark_initial_ineligible' do
    #   let(:sponsorship_state)               { :applicant }
    #   let(:initial_application_state)       { :enrollment_closed }

    #   context  'when initial employer missed binder payment' do

    #     it "should move applications into ineligible state" do
    #       april_sponsors.each do |sponsor|

    #         sponsorship_service = subject.new(benefit_sponsorship: sponsor)
    #         sponsorship_service.mark_initial_ineligible

    #         sponsor.reload

    #         expect(sponsor.applicant?).to be_truthy
    #         expect(sponsor.benefit_applications.first.enrollment_ineligible?).to be_truthy
    #       end
    #     end
    #   end
    # end

    describe '.auto_cancel_enrollment_closed' do
      let(:sponsorship_state)               { :applicant }
      let(:initial_application_state)       { :enrollment_closed }
      let(:renewal_application_state)       { :enrollment_closed }

      context  'when initial employer missed binder payment' do 

        it "should move applications into ineligible state" do
          (april_sponsors + april_renewal_sponsors).each do |sponsor|
            benefit_application = sponsor.benefit_applications.detect{|application| application.is_renewing?}
            benefit_application = sponsor.benefit_applications.first if benefit_application.blank?

            expect(sponsor.applicant?).to be_truthy unless benefit_application.is_renewing?
            expect(benefit_application.enrollment_closed?).to be_truthy
            sponsorship_service = subject.new(benefit_sponsorship: sponsor)
            sponsorship_service.auto_cancel_ineligible

            sponsor.reload
            benefit_application.reload

            expect(sponsor.applicant?).to be_truthy
            expect(benefit_application.canceled?).to be_truthy
          end
        end
      end
    end

    describe '.terminate_pending_sponsor_benefit' do

      let(:initial_application_state)   { :termination_pending }
      let(:ba_start_on) { (current_date.beginning_of_month - 2.months) }

      it 'terminate pending benefit application should be terminated when the end on is reached' do
        april_sponsors.each do |sponsor|
          sponsor.benefit_applications.each do |ba|
            ba.update_attributes!(effective_period: ba_start_on..current_date.prev_day, terminated_on: current_date.prev_month)
          end
          benefit_application = sponsor.benefit_applications.termination_pending.first
          service = subject.new(benefit_sponsorship: sponsor)
          service.terminate_pending_sponsor_benefit
          sponsor.reload
          benefit_application.reload

          expect(benefit_application.aasm_state).to eq :terminated
        end
      end
    end

    describe '.end_open_enrollment' do 
      let(:sponsorship_state)               { :applicant }
      let(:business_policy) { double(success_results: [], fail_results: []) }

      before do
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive(:business_policy_satisfied_for?).and_return(true)
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive(:calculate_pricing_determinations).and_return(true)
        allow_any_instance_of(::BenefitSponsors::BenefitApplications::BenefitApplicationEnrollmentService).to receive(:business_policy).and_return(business_policy)
      end

      context  'For initial employers for whom open enrollment extended' do 
        let(:initial_application_state)       { :enrollment_extended }

        it "should close their open enrollment" do 
          (april_sponsors).each do |sponsor|
            benefit_application = sponsor.benefit_applications.first

            expect(sponsor.applicant?).to be_truthy
            expect(benefit_application.enrollment_extended?).to be_truthy

            sponsorship_service = subject.new(benefit_sponsorship: sponsor)
            sponsorship_service.end_open_enrollment

            sponsor.reload
            benefit_application.reload

            expect(sponsor.applicant?).to be_truthy
            expect(benefit_application.enrollment_closed?).to be_truthy
          end
        end
      end

      context  'For renewal employers for whom open enrollment extended' do 
        let(:renewal_application_state)       { :enrollment_extended }

        it "should close their open enrollment" do 
          (april_renewal_sponsors).each do |sponsor|
            benefit_application = sponsor.benefit_applications.first

            expect(sponsor.active?).to be_truthy
            expect(benefit_application.enrollment_extended?).to be_truthy

            sponsorship_service = subject.new(benefit_sponsorship: sponsor)
            sponsorship_service.end_open_enrollment

            sponsor.reload
            benefit_application.reload

            expect(sponsor.active?).to be_truthy
            expect(benefit_application.enrollment_eligible?).to be_truthy
          end
        end
      end
    end

   describe ".update_fein" do
    let(:benefit_sponsorship) { employer_organization.employer_profile.add_benefit_sponsorship }
    let(:exisitng_org) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)}
    let(:service_instance) { BenefitSponsors::BenefitSponsorships::AcaShopBenefitSponsorshipService.new(benefit_sponsorship: benefit_sponsorship)}
    let(:legal_name) { exisitng_org.legal_name }

    it "should update fein" do
      service_instance.update_fein("048459845")
      expect(benefit_sponsorship.organization.fein).to eq "048459845"
    end

     it "should not update fein" do
      exisitng_org.update_attributes(fein: "098735672")
      error_messages = service_instance.update_fein("098735672")
      expect(error_messages[0]).to eq false
      expect(error_messages[1].first).to eq ("FEIN matches HBX ID #{exisitng_org.hbx_id}, #{exisitng_org.legal_name}")
     end
   end
  end
end
