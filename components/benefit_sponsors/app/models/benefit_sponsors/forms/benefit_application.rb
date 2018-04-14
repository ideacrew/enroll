module BenefitSponsors
  module Forms
    class BenefitApplication
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on
      attr_accessor :fte_count, :pte_count, :msp_count
      
      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      # validates :validate_application_dates

      delegate :benefit_sponsorship, to: :@form_mapping
      delegate :calculate_start_on_dates, :shop_enrollment_timetable, :check_start_on, :calculate_open_enrollment_date, to: :@scheduler

      def initialize(params)
        @scheduler = ::BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
        @form_mapping = BenefitSponsors::BenefitApplications::BenefitApplicationFormMapping.new(params)
      end

      def resource
        @form_mapping.benefit_application
      end

      def calculate_start_on_options
        calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def save
        return false unless self.valid?
        save_result, persisted_object = @form_mapping.save(self)
        return false unless save_result
        @resource = persisted_object
        true
      end
    
      def validate_application_dates
        if start_on <= end_on
          errors.add(:start_on, "can't be later than end on date")
        end
      end

      # def save(benefit_sponsorship, params)
      #   return false unless valid?
      #   params.merge({ benefit_application: reference_benefit_application })
      #   begin
      #     benefit_application_factory = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(benefit_sponsorship, params)
      #     @benefit_application = benefit_application_factory.benefit_application
      #   rescue Exception => e
      #     return false
      #   end
      # end

      # def benefit_sponsor_catalogs
      #   BenefitSponsors::BenefitApplications::BenefitApplicationFactory.benefit_sponsor_catalogs_for(benefit_sponsorship)
      # end

      # def available_effective_date_options
      #   benefit_sponsor_catalogs.map(&:effective_date).map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      # end

      # def self.load_from_object(application)
      #   application_form = self.new

      #   application_form.start_on = application.effective_period.begin
      #   application_form.end_on   = application.effective_period.end
      #   application_form.open_enrollment_start_on = application.open_enrollment_period.begin
      #   application_form.open_enrollment_end_on   = application.open_enrollment_period.end
      #   application_form.fte_count = application.fte_count
      #   application_form.pte_count = application.pte_count
      #   application_form.msp_count = application.msp_count

      #   application_form
      # end

      # def effective_period
      #   start_on..end_on
      # end

      # def open_enrollment_period
      #   open_enrollment_start_on..open_enrollment_end_on
      # end

      # def reference_benefit_application=(benefit_application_id = nil)
      #   @reference_benefit_application = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.find(benefit_sponsorship, benefit_application_id)
      # end

      def assign_application_attributes(atts = {})
        atts.each_pair do |k, v|
          self.send("#{k}=".to_sym, v)
        end
      end
    end
  end
end
