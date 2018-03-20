module SponsoredBenefits
  module Organizations
    class HbxProfile < Profile

      field :cms_id, type: String
      field :us_state_abbreviation, type: String

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
