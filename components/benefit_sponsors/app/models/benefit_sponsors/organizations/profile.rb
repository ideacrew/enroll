# Profile
# Base class with attributes, validations and constraints common to all Profile classes 
# embedded in an Organization
module BenefitSponsors
  module Organizations
    class Profile
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :organization,  class_name: "BenefitSponsors::Organizations::Organization"

      # Profile subclass may sponsor benefits
      field :is_benefit_sponsorship_eligible, type: Boolean, default: false
      field :contact_method

      # Share common attributes across all Profile kinds
      delegate :hbx_id,                                 to: :organization, allow_nil: false
      delegate :legal_name,               :legal_name=, to: :organization, allow_nil: false
      delegate :dba,                      :dba=,        to: :organization, allow_nil: true
      delegate :fein,                     :fein=,       to: :organization, allow_nil: true
  
      embeds_many :office_locations,
                  class_name:"BenefitSponsors::Locations::OfficeLocation"

      embeds_one  :inbox, as: :recipient, cascade_callbacks: true,
                  class_name:"BenefitSponsors::Inboxes::Inbox"

      # Use the Document model for managing any/all documents associated with Organization
      has_many :documents, as: :documentable,
               class_name: "BenefitSponsors::Documents::Document"

      validates_presence_of :organization, :office_locations
      accepts_nested_attributes_for :office_locations

      # @abstract profile subclass is expected to implement #initialize_profile
      # @!method initialize_profile
      # Initialize settings for the abstract profile
      after_initialize :initialize_profile, :build_nested_models

      alias_method :is_benefit_sponsorship_eligible?, :is_benefit_sponsorship_eligible

      # # TODO make benefit sponsorships a has_many collection
      # # Inverse of BenefitSponsoship#organization_profile
      # def benefit_sponsorship
      #   raise Errors::SponsorshipIneligibleError unless is_benefit_sponsorship_eligible?
      #   return @benefit_sponsorship if defined?(@benefit_sponsorship)
      #   @benefit_sponsorship = organization.benefit_sponsorships.detect { |benefit_sponsorship| benefit_sponsorship._id == self.benefit_sponsorship_id }
      # end

      # def benefit_sponsorship=(benefit_sponsorship)
      #   return unless is_benefit_sponsorship_eligible?
      #   write_attribute(:benefit_sponsorship_id, benefit_sponsorship._id)
      #   @benefit_sponsorship = benefit_sponsorship
      # end

      def primary_office_location
        office_locations.detect(&:is_primary?)
      end

      def is_primary_office_local?
        primary_office_location.address.state.to_s.downcase == Settings.aca.state_abbreviation.to_s.downcase
      end

      def add_benefit_sponsorship
        return unless is_benefit_sponsorship_eligible?
        organization.sponsor_benefits_for(self)
      end

      def benefit_sponsorships
        organization.benefit_sponsorships.collect { |benefit_sponsorship| benefit_sponsorship.profile_id.to_s == _id.to_s }
      end

      class << self
        def find(id)
          organizations = Organization.where("profiles._id" => BSON::ObjectId.from_string(id)).entries
          return unless organizations.size == 1
          organizations.first.profiles.detect { |profile| profile.id.to_s == id.to_s }
        end
      end

      def legal_name
        organization.legal_name
      end

      private

      # Subclasses are expected to override this method
      def initialize_profile
      end

      def build_nested_models
      end
    end
  end
end
