module BenefitSponsors
  module Services
    class BenefitApplicationService
      attr_reader :params

      def initialize(params)
        @params = params
      end

      def store!(form)
        model_attributes = form_model_to_attributes(form)

        # This will instantiate a new application when benefit application is nil or update existing application when present
        @benefit_application = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(
          benefit_sponsorship, benefit_application, model_attributes
        )
        
        save_success = @benefit_application.save

        unless save_success
          map_errors_for(form)
          return false
        end

        true
      end

      def form_model_to_attributes(form) #create/update
        {
          effective_period: (form.start_on..form.end_on),
          open_enrollment_period: (form.open_enrollment_start_on..form.open_enrollment_end_on),
          fte_count: form.fte_count,
          pte_count: form.pte_count,
          msp_count: form.msp_count
        }
      end

      def attributes_to_form_params # edit
        {
          start_on: benefit_application.effective_period.min,
          end_on: benefit_application.effective_period.max,
          open_enrollment_start_on: benefit_application.open_enrollment_period.min,
          open_enrollment_end_on: benefit_application.open_enrollment_period.max,
          fte_count: benefit_application.fte_count,
          pte_count: benefit_application.pte_count,
          msp_count: benefit_application.msp_count
        }
      end

      def benefit_sponsorship
        return @benefit_sponsorship if defined? @benefit_sponsorship
        @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:benefit_sponsorship_id])
      end

      def benefit_application
        return @benefit_application if defined? @benefit_application
        @benefit_application = benefit_sponsorship.benefit_applications.find(params[:benefit_application_id])
      end

      def self.benefit_sponsor_catalogs_for(benefit_sponsorship)
        benefit_sponsorship.benefit_sponsor_catalogs
      end

      # We can cheat here because our form and our model are so
      # close together - normally this will be more complex
      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end

      def map_errors_for(form)
        benefit_application.errors.each do |att, err|
          form.errors.add(map_model_error_attribute(att), err)
        end
      end
    end
  end
end