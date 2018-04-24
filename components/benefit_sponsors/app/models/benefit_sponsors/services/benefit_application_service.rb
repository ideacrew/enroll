module BenefitSponsors
  module Services
    class BenefitApplicationService
      attr_reader :benefit_application_factory

      def initialize(factory_kind = BenefitSponsors::BenefitApplications::BenefitApplicationFactory)
        @benefit_application_factory = factory_kind
      end

      # load defaults from models
      def load_default_form_params(form)
        form
      end

      def load_form_metadata(form)
        # form.start_on_options = calculate_start_on_options
        form.start_on_options = calculate_dates
      end

      def load_form_params_from_resource(form)
        benefit_application = find_model_by_id(form.id)
        attributes_to_form_params(benefit_application, form)
      end

      def scheduler
        return @scheduler if defined? @scheduler
        @scheduler = ::BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      end

      # Responsible for calculating all the possible dataes
      def calculate_dates
        possible_dates = Hash.new
        scheduler.calculate_start_on_dates.each do |date|
          possible_dates[date] = open_enrollment_dates(date).merge(enrollment_schedule(date))
        end
        possible_dates
      end

      # def calculate_start_on_options
      #   scheduler.calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      # end

      def is_start_on_valid?(start_on)
        start_on_result(start_on)[:result] == "ok"
      end

      def start_on_result(start_on)
        scheduler.check_start_on(start_on)
      end

      def open_enrollment_dates(start_on)
        scheduler.calculate_open_enrollment_date(start_on) if is_start_on_valid?(start_on)
      end

      def enrollment_schedule(start_on)
        scheduler.shop_enrollment_timetable(start_on) if is_start_on_valid?(start_on)
      end
  
      def save(form) 
        benefit_application = benefit_application_factory.call() # build cca/dc application
        store(form, benefit_application)
      end
     
      def update(form) 
        benefit_application = find_model_by_id(form.id)
        form_params_to_attributes(form, benefit_application)
        store(form, benefit_application)
      end
    
      # TODO: Test this query for benefit applications cca/dc
      def find_model_by_id(id)
        ::BenefitMarkets::Products::ProductPackage.find(id)
      end

      def attributes_to_form_params
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

      def form_params_to_attributes(form, benefit_application)
        model_attributes = {
          effective_period: (form.start_on..form.end_on),
          open_enrollment_period: (form.open_enrollment_start_on..form.open_enrollment_end_on),
          fte_count: form.fte_count,
          pte_count: form.pte_count,
          msp_count: form.msp_count
        }

        benefit_application.assign_attributes(model_attributes)
      end

      def store(form, benefit_application)
        valid_according_to_factory = benefit_application_factory.validate(benefit_application)
        unless valid_according_to_factory
          map_errors_for(benefit_application, onto: form)
          return [false, nil]
        end
        save_successful = benefit_application.save
        unless save_successful 
          map_errors_for(benefit_application, onto: form)
          return [false, nil]
        end
        [true, benefit_application]
      end

      def map_errors_for(benefit_application, onto:)
        benefit_application.errors.each do |att, err|
          onto.errors.add(map_model_error_attribute(att), err)
        end
      end

      def self.benefit_sponsor_catalogs_for(benefit_sponsorship)
        benefit_sponsorship.benefit_sponsor_catalogs
      end

      # We can cheat here because our form and our model are so
      # close together - normally this will be more complex
      def map_model_error_attribute(model_attribute_name)
        model_attribute_name
      end
    end
  end
end