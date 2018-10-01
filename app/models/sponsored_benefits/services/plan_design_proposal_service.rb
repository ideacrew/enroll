module SponsoredBenefits
  module Services
    class PlanDesignProposalService

      attr_reader :proposal, :kind

      def initialize(attrs={})
        @kind = attrs[:kind]
        @proposal = attrs[:proposal]
      end

      def ensure_benefits
        self.send("ensure_#{kind}_benefits")
      end

      def save_benefits(attrs={})
        self.send("save_#{kind}_benefits", attrs)
      end

      def ensure_health_benefits
        if benefit_group.relationship_benefits.empty?
          benefit_group.build_relationship_benefits
        end
        if benefit_group.composite_tier_contributions.empty?
          benefit_group.build_composite_tier_contributions
        end
        benefit_group
      end

      def ensure_dental_benefits
        if benefit_group.build_dental_relationship_benefits.empty?
          benefit_group.build_dental_relationship_benefits 
        end
        benefit_group
      end

      def save_health_benefits(attrs={})
        benefit_group(attrs)
      end

      def save_dental_benfits(attrs={})
      end

      def benefit_group(attrs={})
        return @benefit_group if defined? @benefit_group
        @benefit_group = application.benefit_groups.first || application.benefit_groups.build(attrs)
      end

      def application
        return @application if defined? @application
        sponsorship = proposal.profile.benefit_sponsorships.first
        @application = sponsorship.benefit_applications.first
      end
    end
  end
end
