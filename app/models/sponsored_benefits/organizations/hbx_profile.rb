module SponsoredBenefits
  module Organizations
    class HbxProfile < Profile

      field :cms_id, type: String
      field :us_state_abbreviation, type: String

      private

      def initialize_profile
        return unless benefit_sponsorship_eligible.blank?

        write_attribute(:benefit_sponsorship_eligible, true)
        @benefit_sponsorship_eligible = true
        self
      end

    end
  end
end
