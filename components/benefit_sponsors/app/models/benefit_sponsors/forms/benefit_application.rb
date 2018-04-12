module BenefitSponsors
  module Forms
    class BenefitApplication
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on
      attr_accessor :fte_count, :pte_count, :msp_count
      attr_accessor :benefit_sponsorship, :reference_benefit_application, :benefit_sponsor_catalogs, :benefit_application
      
      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      validates :validate_application_dates

      def initialize(benefit_sponsorship, params = {})
        @benefit_sponsorship = benefit_sponsorship
        assign_application_attributes(params)
      end

      def validate_application_dates
        if start_on <= end_on
          errors.add(:start_on, "can't be later than end on date")
        end
      end

      def benefit_market
        benefit_sponsorship.benefit_market
      end

      def save(benefit_sponsorship, params)
        return false unless valid?
        params.merge({benefit_application: reference_benefit_application}) if reference_benefit_application.present?

        begin
          benefit_application_factory = BenefitSponsors::BenefitApplications::BenefitApplicationFactory.call(benefit_sponsorship, params)
          @benefit_application = benefit_application_factory.benefit_application
        rescue Exception => e
          return false
        end
      end

      def benefit_sponsor_catalogs
        BenefitSponsors::BenefitApplications::BenefitApplicationFactory.benefit_sponsor_catalogs_for(benefit_sponsorship)
      end

      def available_effective_date_options
        benefit_sponsor_catalogs.map(&:effective_date).map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def self.load_from_object(application)
        application_form = self.new
        application_form.start_on = application.effective_period.begin
        application_form.end_on   = application.effective_period.end
        application_form.open_enrollment_start_on = application.open_enrollment_period.begin
        application_form.open_enrollment_end_on   = application.open_enrollment_period.end
        application_form.fte_count = application.fte_count
        application_form.pte_count = application.pte_count
        application_form.msp_count = application.msp_count
        application_form
      end

      def effective_period
        start_on..end_on
      end

      def open_enrollment_period
        open_enrollment_start_on..open_enrollment_end_on
      end

      def assign_application_attributes(atts = {})
        atts.each_pair do |k, v|
          self.send("#{k}=".to_sym, v)
        end
      end
    end
  end
end
