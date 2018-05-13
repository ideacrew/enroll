module BenefitSponsors
  module Organizations
    class AcaShopCcaEmployerProfile < BenefitSponsors::Organizations::Profile
      # include Concerns::AcaRatingAreaConfigConcern
      include Concerns::EmployerProfileConcern

      field :sic_code,                type: String

      embeds_one  :employer_attestation

      # TODO use SIC code validation
      validates_presence_of :sic_code

      # TODO move all this into builder

            # def primary_office_location
            #   (organization || plan_design_organization).primary_office_location
            # end

            # def rating_area
            #   if use_simple_employer_calculation_model?
            #     return nil
            #   end
            #   RatingArea.rating_area_for(primary_office_location.address)
            # end

            # def service_areas
            #   if use_simple_employer_calculation_model?
            #     return nil
            #   end
            #   CarrierServiceArea.service_areas_for(office_location: primary_office_location)
            # end

            # def service_areas_available_on(date)
            #   if use_simple_employer_calculation_model?
            #     return []
            #   end
            #   CarrierServiceArea.service_areas_available_on(primary_office_location.address, date.year)
            # end

            # def service_area_ids
            #   if use_simple_employer_calculation_model?
            #     return nil
            #   end
            #   service_areas.collect { |service_area| service_area.service_area_id }.uniq
            # end
      #### 


      private

      def site
        return @site if defined? @site
        @site = BenefitSponsors::Site.by_site_key(:cca).first
      end

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
