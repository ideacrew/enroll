# Attributes, validations and constraints common to all Profile classes embedded in an Organization
module SponsoredBenefits
  module Organizations
    class Profile
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :organization

      field :profile_source, type: String

      # Terminated twice for non-payment?
      field :eligible_for_benefit_sponsorship, type: Boolean

      # Share common attributes across all Profile kinds
      delegate :hbx_id, to: :organization, allow_nil: true
      delegate :legal_name, :legal_name=, to: :organization, allow_nil: true
      delegate :dba, :dba=, to: :organization, allow_nil: true
      delegate :fein, :fein=, to: :organization, allow_nil: true
      delegate :is_active, :is_active=, to: :organization, allow_nil: false
      delegate :updated_by, :updated_by=, to: :organization, allow_nil: false


      # Only one benefit_sponsorship may be active.  Enable many to support changes and history tracking
      embeds_many  :benefit_sponsorships, as: :benefit_sponsorable, class_name: "SponsoredBenefits::BenefitSponsorships::BenefitSponsorship"


      def self.find
        org = Organizations::PlanDesignOrganization.find_by_profile(self)
        org.profile if org.present
      end

    end
  end
end
