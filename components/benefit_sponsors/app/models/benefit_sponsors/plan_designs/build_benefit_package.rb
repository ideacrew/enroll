module BenefitSponsors
  module PlanDesigns
    class BuildBenefitPackage < CompositeTask

      def initialize
        # super("Process an organization and it's members initial benefit coverage")
        # add_subtask(SponsorBenefits::FindOrCreateSponsorOrganization.new)
        # add_subtask(SponsorBenefits::HireBroker.new)

        add_subtask(BenefitSponsors::PlanDesigns::GetEligibleProductPackages)
        add_subtask(BenefitSponsors::PlanDesigns::TransformSelectedProductToBenefit)
        add_subtask()
        add_subtask(BuildSponsoredBenefit)
        add_subtask(GetEligibleProductPackages)
      end

    end
  end
end
