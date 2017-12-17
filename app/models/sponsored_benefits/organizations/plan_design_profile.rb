module SponsoredBenefits
  module Organizations
    class PlanDesignProfile < Profile

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"
      embeds_many :benefit_applications, class_name: "SponsoredBenefits::Organizations::BenefitApplications::BenefitApplication"

    end
  end
end
