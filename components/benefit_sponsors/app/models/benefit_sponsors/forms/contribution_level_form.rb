module BenefitSponsors
  module Forms
    class ContributionLevelForm
      extend  ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :display_name, String
      attribute :contribution_unit_id, String
      attribute :is_offered, Boolean
      attribute :order, Integer
      attribute :contribution_factor, Float
      attribute :min_contribution_factor, Float
      attribute :contribution_cap, Float
      attribute :flat_contribution_amount, Float

      def self.for_new
        contribution_levels.collect do |level_attrs|
          form = self.new(level_attrs)
          form
        end
      end

      # Benefit Sponsor Catalog
      def self.contribution_levels

        # [
        #   {
        #     display_name: 'employee',
        #     is_offered: true,
        #     order: 0,
        #     contribution_factor: 0.75,
        #     min_contribution_factor: 0.50
        #   },
        #   {
        #     display_name: 'spouse',
        #     is_offered: true,
        #     order: 1,
        #     contribution_factor: 0.75,
        #     min_contribution_factor: 0.50
        #   },
        #   {
        #     display_name: 'dependent',
        #     is_offered: true,
        #     order: 2,
        #     contribution_factor: 0.75,
        #     min_contribution_factor: 0.50
        #   }
        # ]
      end
    end
  end
end
