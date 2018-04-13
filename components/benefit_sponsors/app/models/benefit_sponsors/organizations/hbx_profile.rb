module BenefitSponsors
  module Organizations
    class HbxProfile < BenefitSponsors::Organizations::Profile

      # field :benefit_sponsorship_id,  type: BSON::ObjectId
      field :cms_id,                  type: String
      field :us_state_abbreviation,   type: String

      validates_presence_of :us_state_abbreviation, :cms_id

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end

      def build_nested_models
        build_inbox if inbox.nil?
      end
    end
  end
end
