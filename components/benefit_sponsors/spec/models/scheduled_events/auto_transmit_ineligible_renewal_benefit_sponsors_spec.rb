require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

module BenefitSponsors
  RSpec.describe "auto transmit ineligible renewal benefit sponsors", dbclean: :after_each do

    describe "renewal ineligble employer monthly transmission for the month MARCH:
       - employer A renewing benefit application :
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to enrollment_eligible state

       - employer B renewing benefit application:
         - published renewal benefit application
         - Open Enrollment Closed
         - benefit application moved to inenrollment_ineligible state
    ", dbclean: :after_each do

      before :all do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_cca_site_with_hbx_profile_and_benefit_market }
      let!(:previous_rating_area) { create_default(:benefit_markets_locations_rating_area, active_year: Date.current.year - 1) }
      let!(:previous_service_area) { create_default(:benefit_markets_locations_service_area, active_year: Date.current.year - 1) }
      let!(:rating_area) { create_default(:benefit_markets_locations_rating_area) }
      let!(:service_area) { create_default(:benefit_markets_locations_service_area) }

      let(:initial_application_state)       { :active }
      let!(:this_year)                       { TimeKeeper.date_of_record.year }
      let(:april_effective_date)            { Date.new(this_year,4,1) }

      let!(:employer_A)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                 :with_renewal_benefit_application, initial_application_state: :active,
                                 renewal_application_state: :enrollment_eligible,
                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                                 aasm_state: :active)}

      let!(:employer_B)  { build(:benefit_sponsors_benefit_sponsorship, :with_organization_cca_profile,
                                 :with_renewal_benefit_application, initial_application_state: :active,
                                 renewal_application_state: :enrollment_ineligible,
                                 default_effective_period: (april_effective_date..(april_effective_date + 1.year - 1.day)), site: site,
                                 aasm_state: :active)}

      context "renewal employer ineligible transmission day" do

        before :each do
          active_benefit_app = employer_A.benefit_applications.where(aasm_state: :active).first
          employer_A.benefit_applications.where(aasm_state: :enrollment_eligible).first.update_attributes(predecessor_id: active_benefit_app.id)

          active_benefit_app = employer_B.benefit_applications.where(aasm_state: :enrollment_ineligible).first
          employer_B.benefit_applications.where(aasm_state: :enrollment_ineligible).first.update_attributes(predecessor_id: active_benefit_app.id)
        end

        it "should not transmit employer_A " do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,4,1))
          expect(ActiveSupport::Notifications).to_not receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_carrier_dropped", {employer_id: employer_A.profile.hbx_id, event_name: 'benefit_coverage_renewal_carrier_dropped'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,4,1))
        end

        it "should transmit employer_B with carrier drop event" do
          allow_any_instance_of(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year,4,1))
          expect(ActiveSupport::Notifications).to receive(:instrument).with("acapi.info.events.employer.benefit_coverage_renewal_carrier_dropped", {employer_id: employer_B.profile.hbx_id, event_name: 'benefit_coverage_renewal_carrier_dropped'})
          BenefitSponsors::ScheduledEvents::AcaShopScheduledEvents.new(Date.new(TimeKeeper.date_of_record.year,4,1))
        end
      end
    end
  end
end
