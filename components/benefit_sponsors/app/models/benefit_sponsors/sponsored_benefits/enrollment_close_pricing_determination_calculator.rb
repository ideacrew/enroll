module BenefitSponsors
  module SponsoredBenefits
    class EnrollmentClosePricingDeterminationCalculator
      def self.call(benefit_application, calc_date)
        return nil
        calculator = ::BenefitSponsors::SponsoredBenefits::HbxEnrollmentPricingDeterminationCalculator.new(benefit_application.benefit_sponsorship, calc_date)
        benefit_application.benefit_packages.each do |bp|
          bp.sponsored_benefits.each do |sb|
            waiver_count = waiver_count_for(sb, calc_date)
            enrollment_id_list = enrollment_id_list_for(sb, calc_date)
            updated_benefit = calculator.calculate(sb, enrollment_id_list, waiver_count)
            updated_benefit.save!
          end
        end
      end

      def self.waiver_count_for(sb, calc_date)
        0
      end

      def enrollment_id_list_for(sb, calc_date)
        []
      end
    end
  end
end
