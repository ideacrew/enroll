module SponsoredBenefits
  module Organizations
    class AcaShopCcaEmployerProfile < Profile

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      field :sic_code, type: String

      field :profile_source, type: String, default: "broker_quote"
      field :contact_method, type: String, default: "Only Electronic communications"

      embeds_one  :employer_attestation

      delegate :customer_profile_id, to: :plan_design_organization
    end
  end
end
