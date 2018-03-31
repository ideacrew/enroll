module BenefitSponsors
  module PlanDesigns
    class BuildBenefitPackage < CompositeTask

      def initialize
        super(BenefitSponsors::BenefitPackages::BenefitPackage)

        add_subtask(BenefitSponsors::PlanDesigns::GetEligibleProductPackages)
        add_subtask(BenefitSponsors::PlanDesigns::SetProbationPeriod)

#     # GetBenefitCatalog   (effective on date)
#     # GetEligibleProductPackage  (effective on date, effective on kind)
#     # TransformProductPackage

#   benefit_package
#             add_subtask(BenefitSponsors::PlanDesigns::SetProbationPeriod.new)
#             add_subtask(BenefitSponsors::PlanDesigns::GetEligiblePackageList.new)

#             add_subtask(BenefitSponsors::PlanDesigns::TransformPackageToSponsoredBenefit.new)

#   sponsored_benefit

#             add_subtask(BenefitSponsors::PlanDesigns::BuildSponsoredBenefit.new)

#             add_subtask(BenefitSponsors::PlanDesigns::SetHealthOneIssuerOptions.new)
#             add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

#             add_subtask(BenefitSponsors::PlanDesigns::SetHealthOnePlanOptions.new)
#             add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

#             add_subtask(BenefitSponsors::PlanDesigns::SetHealthCompositePlanOptions.new)
#             add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)
#             add_subtask(BenefitSponsors::PlanDesigns::CalculateCompositeRate.new)

#             add_subtask(BenefitSponsors::PlanDesigns::SetHealthMetalLevelOptions.new)
#             add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

#             add_subtask(BenefitSponsors::PlanDesigns::SetDentalOnePlanOptions.new)
#             add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

#             add_subtask(BenefitSponsors::PlanDesigns::SetDentalManyPlanOptions.new)
#             add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)
      end
    end
  end
end





