# Profile that supports Plan Design and Quoting functions
module SponsoredBenefits
  module Organizations
    class PlanDesignProfile < Profile

      field :profile_source, type: String, default: "broker_quote"
      field :contact_method, type: String, default: "Only Electronic communications"
      field :sic_code, type: String

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"
      embeds_many :plan_design_proposals, class_name: "SponsoredBenefits::BenefitSponsorships::PlanDesignProposal"

      def self.find(id)
        org = Organizations::PlanDesignOrganization.where(:"plan_design_profile._id" => BSON::ObjectId.from_string(id)).first
        org.plan_design_profile if org.present?
      end
    end
  end
end
