module BenefitSponsors
  module Organizations
    class FehbEmployerProfile < BenefitSponsors::Organizations::Profile
      include Mongoid::Document
      include BenefitSponsors::Concerns::EmployerProfileConcern

      field :no_ssn, type: Boolean, default: false
      field :enable_ssn_date, type: DateTime
      field :disable_ssn_date, type: DateTime

      def rating_area
        # FIX this
      end

      def sic_code
        # Fix this
      end

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end

      def build_nested_models
        return if inbox.present?
        build_inbox
        welcome_subject = "Welcome to #{BenefitSponsorsRegistry[:enroll_app].settings(:short_name).item}"
        welcome_body = "#{BenefitSponsorsRegistry[:enroll_app].settings(:short_name).item} is the "\
        "#{BenefitSponsorsRegistry[:enroll_app].settings(:short_name).item}'s online marketplace "\
        "where benefit sponsors may select and offer products that meet their member's needs and budget."
        unless inbox.messages.where(body: welcome_body).present?
          inbox.messages.new(subject: welcome_subject, body: welcome_body, from: BenefitSponsorsRegistry[:enroll_app].settings(:short_name).item, created_at: Time.now.utc)
        end
      end
    end
  end
end
