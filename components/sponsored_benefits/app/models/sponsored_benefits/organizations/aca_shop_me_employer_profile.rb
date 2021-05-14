# frozen_string_literal: true

module SponsoredBenefits
  module Organizations
    # Employer profile class for Maine. Should be deprecated eventually.
    class AcaShopMeEmployerProfile < Profile
      include Concerns::AcaRatingAreaConfigConcern

      field :sic_code, type: String if ::EnrollRegistry.feature_enabled?(:sic_codes)
      embeds_one  :employer_attestation
      embedded_in :plan_design_proposal, class_name: "SponsoredBenefits::Organizations::PlanDesignProposal"

      after_initialize :initialize_benefit_sponsorship

      def primary_office_location
        (organization || plan_design_organization).primary_office_location
      end

      def rating_area
        return nil if use_simple_employer_calculation_model?
        RatingArea.rating_area_for(primary_office_location.address)
      end

      def service_areas
        return nil if use_simple_employer_calculation_model?
        CarrierServiceArea.service_areas_for(office_location: primary_office_location)
      end

      def service_areas_available_on(date)
        return [] if use_simple_employer_calculation_model?
        CarrierServiceArea.service_areas_available_on(primary_office_location.address, date.year)
      end

      def service_area_ids
        return nil if use_simple_employer_calculation_model?
        service_areas.collect(&:service_area_id).uniq
      end

      private

      def initialize_benefit_sponsorship
        benefit_sponsorships.build(benefit_market: :aca_shop_me, enrollment_frequency: :rolling_month) if benefit_sponsorships.blank?
      end
    end
  end
end
