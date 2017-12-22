module SponsoredBenefits
  class BenefitSponsorships::PlanDesignEmployerProfile
    include Mongoid::Document

    #embedded_in :plan_design_organization, class_name: "SponsoredBenefits::Organizations::PlanDesignOrganization"

    field :entity_kind, type: String
    field :sic_code, type: String
    field :legal_name, type: String
    field :dba, type: String

    embeds_many :office_locations, class_name:"SponsoredBenefits::Organizations::OfficeLocation"

    def self.find(id)
      organizations = PlanDesignOrganization.where("employer_profile._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile : nil
    rescue
      log("Can not find employer_profile with id #{id}", {:severity => "error"})
      nil
    end
  end
end
