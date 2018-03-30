module BenefitSponsors
  module PlanDesigns
    class BuildBenefitPackage < CompositeTask

      def initialize
        super("Define benefit products that a sponsor will offer to a set of members")

        add_subtask(BenefitSponsors::PlanDesigns::AssociateMembers.new) # If default BenefitPackage

        add_subtask(BenefitSponsors::PlanDesigns::GetEligiblePackageList.new)
          add_subtask(BenefitSponsors::PlanDesigns::SetProbationPeriod.new)
          add_subtask(BenefitSponsors::PlanDesigns::TransformPackageToBenefit.new)

            add_subtask(BenefitSponsors::PlanDesigns::BuildHealthSponsoredBenefit.new)
              add_subtask(BenefitSponsors::PlanDesigns::SetHealthOneIssuerOptions.new)
                add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

              add_subtask(BenefitSponsors::PlanDesigns::SetHealthOnePlanOptions.new)
                add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

              add_subtask(BenefitSponsors::PlanDesigns::SetHealthCompositePlanOptions.new)
                add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)
                add_subtask(BenefitSponsors::PlanDesigns::CalculateCompositeRate.new)

              add_subtask(BenefitSponsors::PlanDesigns::SetHealthMetalLevelOptions.new)
                add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

            add_subtask(BenefitSponsors::PlanDesigns::BuildDentalSponsoredBenefit.new)
              add_subtask(BenefitSponsors::PlanDesigns::SetDentalOnePlanOptions.new)
                add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)
              add_subtask(BenefitSponsors::PlanDesigns::SetDentalManyPlanOptions.new)
                add_subtask(BenefitSponsors::PlanDesigns::SetSponsorContribution.new)

      end
    end
  end
end
