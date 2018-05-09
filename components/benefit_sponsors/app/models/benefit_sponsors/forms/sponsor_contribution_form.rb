module BenefitSponsors
  module Forms
    class SponsorContributionForm
      
      include Virtus.model
      include ActiveModel::Model

      attribute :contribution_levels, Array[ContributionLevelForm]
      attr_accessor :contribution_levels

      # def contribution_levels_attributes=(attributes)
      #   @contribution_levels ||= []
      #   attributes.each do |i, contribution_level_attributes|
      #     @contribution_levels.push(ContributionLevelForm.new(contribution_level_attributes))
      #   end
      # end

      def self.for_new
        form = self.new
        form.contribution_levels = ContributionLevelForm.for_new
        form
      end

      def self.for_create(params)
        contribution_level_params = params.delete(:contribution_levels_attributes)
        form = self.new(params)
        contribution_level_params.each do |index, level_params|
          form.contribution_levels << ContributionLevelForm.for_create(level_params)
        end
        form
      end
    end
  end
end