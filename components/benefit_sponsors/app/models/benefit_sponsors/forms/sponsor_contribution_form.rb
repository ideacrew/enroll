module BenefitSponsors
  module Forms
    class SponsorContributionForm
      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :contribution_levels, Array[ContributionLevelForm]

      def self.for_new
        form = self.new
        form.contribution_levels = ContributionLevelForm.for_new
        form
      end
    end
  end
end