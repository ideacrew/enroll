module SponsoredBenefits
  module BenefitApplications
    class AcaShopCcaBenefitApplicationBuilder < BenefitApplicationBuilder

      attr_reader :record

      # def initialize(plan_design_organization, options={})
      #   @application_class = BenefitApplications::AcaShopCcaBenefitApplication
      #   @options = options
      #   # @record = plan_design_organization.plan_design_proposals.new
      #   # @record.title = options.fetch(:title)
      #   @record.profile = Organizations::AcaShopCcaEmployerProfile.new
      #   sponsorship = @record.profile.benefit_sponsorships.build({
      #     benefit_market: :aca_shop_cca
      #   }.merge(sponsorship_attr))
      #   sponsorship.benefit_applications << @application_class.new(application_attr)
      # end

      # benefit_application = AcaShopCcaBenefitApplicationBuilder.build do |builder|
      #   builder.set_organization(organization)
      #   builder.set_options(options)        
      # end

      def initialize
        @benefit_application = AcaShopCcaBenefitApplication.new
      end

      # def add_broker(new_broker)
      #   @broker = new_broker
      # end

      # def add_employer_attestation(new_employer_attestation)
      # end

      # def benefit_application
      #   # raise "" if open_enrollment_term.blank?
      #   @benefit_application
      # end

      # def reset
      #   @benefit_application = @application_class.new
      # end

      private
      
      def one_year_period(begin_on)
        (begin_on..(begin_on + 1.year - 1.day))
      end
    end
  end
end
