module BenefitSponsors
  module Organizations
    class Profile
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :organization,  class_name: "BenefitSponsors::Organizations::Organization"

      field :is_benefit_sponsorship_eligible, type: Boolean,  default: false
      field :contact_method,                  type: Symbol,   default: :paper_and_electronic

      embeds_many :office_locations,
        class_name:"BenefitSponsors::Locations::OfficeLocation", cascade_callbacks: true

      class << self
        def find(id)
          return nil if id.blank?
          organization = BenefitSponsors::Organizations::Organization.where("profiles._id" => BSON::ObjectId.from_string(id)).first
          organization.profiles.detect { |profile| profile.id.to_s == id.to_s } if organization.present?
        end
      end
    end
  end
end
