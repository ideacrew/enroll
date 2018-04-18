module BenefitSponsors
  module Services
    class BenefitApplicationService

      attr_reader :params

      def initialize(params)
        @params = params
        @benefit_application_factory = BenefitSponsors::BenefitApplications::BenefitApplicationFactory
      end

      def save(form)
        benefit_application = build_object_from_form(form)
        benefit_application.save
      end

      def params_to_attributes(params)

      end

      def attributes_to_params(klass)

      end

      def benefit_sponsorship
        return @benefit_sponsorship if defined? @benefit_sponsorship
        @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id])
      end

      def benefit_application
        return @benefit_application if defined? @benefit_application
        @benefit_application = benefit_sponsorship.benefit_applications.find(params[:benefit_application_id])
      end

      def build_object_from_form(form)
        @benefit_application_factory.call(benefit_sponsorship: benefit_sponsorship, benefit_application: benefit_application, 
        {
          effective_period: (form.start_on..form.end_on),
          open_enrollment_period: (form.open_enrollment_start_on..form.open_enrollment_end_on),
          fte_count: form.fte_count,
          pte_count: form.pte_count,
          msp_count: form.msp_count
          })
      end

      def self.benefit_sponsor_catalogs_for(benefit_sponsorship)
        benefit_sponsorship.benefit_sponsor_catalogs
      end
    end
  end
end