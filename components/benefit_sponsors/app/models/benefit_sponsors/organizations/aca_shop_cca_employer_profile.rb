module BenefitSponsors
  module Organizations
    class AcaShopCcaEmployerProfile < BenefitSponsors::Organizations::Profile
      include Concerns::AcaRatingAreaConfigConcern
      include Concerns::EmployerProfileConcern

      field :benefit_sponsorship_id,  type: BSON::ObjectId
      field :sic_code,                type: String
      field :rating_area_id,          type: BSON::ObjectId

      embeds_one  :employer_attestation

      # TODO use SIC code validation
      validates_presence_of :sic_code, :rating_area_id


      def rating_area=(new_rating_area)
        write_attribute(:rating_area_id, new_rating_area._id)
        @rating_area = new_rating_area
      end

      def rating_area
        return unless rating_area_id.present?
        return @rating_area if defined? @rating_area
        @rating_area = BenefitSponsors::Locations::RatingArea.find(rating_area_id)
      end


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

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end

    end
  end
end
