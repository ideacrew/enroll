module BenefitSponsors
  module Organizations
    class AcaShopCcaEmployerProfile < BenefitSponsors::Organizations::Profile
      # include Concerns::AcaRatingAreaConfigConcern
      include BenefitSponsors::Concerns::EmployerProfileConcern

      field :sic_code,  type: String

      # TODO use SIC code validation
      validates_presence_of :sic_code

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
        #TODO: After migration uncomment the lines below to get Welcome message for Initial Inbox creation
        # welcome_subject = "Welcome to #{Settings.site.short_name}"
        # welcome_body = "#{Settings.site.short_name} is the #{Settings.aca.state_name}'s online marketplace where benefit sponsors may select and offer products that meet their member's needs and budget."
        # inbox.messages.new(subject: welcome_subject, body: welcome_body)
      end
    end
  end
end
