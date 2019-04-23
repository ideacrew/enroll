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
      embeds_one  :inbox, as: :recipient, cascade_callbacks: true,
                  class_name:"BenefitSponsors::Inboxes::Inbox"

      after_initialize :build_nested_models

      delegate :hbx_id,                   to: :organization, allow_nil: false
      delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
      delegate :dba,        :dba=,        to: :organization, allow_nil: true
      delegate :fein,       :fein=,       to: :organization, allow_nil: true
      delegate :entity_kind,              to: :organization, allow_nil: true

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