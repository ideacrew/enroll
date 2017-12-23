module SponsoredBenefits
  module Organizations
    class PlanDesignProposal

      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

      field :title, type: String
      field :claim_date, type: Date
      field :submitted_date, type: Date

      embeds_one :profile, class_name: "SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile"

      scope :datatable_search, ->(query) { self.where({"$or" => ([{"title" => Regexp.compile(Regexp.escape(query), true)}])}) }


      def self.find(id)
        organization = SponsoredBenefits::Organizations::PlanDesignOrganization.where("plan_design_proposals._id" => BSON::ObjectId.from_string(id)).first
        organization.plan_design_proposals.detect{|proposal| proposal.id == BSON::ObjectId.from_string(id)}
      end
    end
  end
end
