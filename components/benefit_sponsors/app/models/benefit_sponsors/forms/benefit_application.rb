module BenefitSponsors
  module Forms
    class BenefitApplication
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on
      attr_accessor :fte_count, :pte_count, :msp_count
      attr_accessor :benefit_sponsorship, :reference_benefit_application, :available_effective_date_options, :benefit_sponsor_catalogs, :benefit_application
      
      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      validates :validate_application_dates

      def initialize(params = {})
        assign_application_attributes(params)
        get_benefit_sponsor_catalogs
        init_effective_date_options
      end

      def validate_application_dates
        if start_on <= end_on
          errors.add(:start_on, "can't be later than end on date")
        end
      end

      def assign_application_attributes(atts = {})
        atts.each_pair do |k, v|
          self.send("#{k}=".to_sym, v)
        end
      end

      def effective_period
        start_on..end_on
      end

      def open_enrollment_period
        open_enrollment_start_on..open_enrollment_end_on
      end

      def save
        return false unless valid?
        @benefit_application = build_benefit_application
        # @benefit_application_form.errors.add(benefit_application: @benefit_application_form.benefit_application.errors)
        @benefit_application.save
      end

      def build_benefit_application
        BenefitSponsors::Factories::BenefitApplicationFactory.call(self, benefit_sponsorship)
      end

      def get_benefit_sponsor_catalog
        @benefit_sponsor_catalogs = benefit_sponsorship.benefit_market.benefit_sponsor_catalogs_for(benefit_sponsorship.rating_area)
      end

      def init_effective_date_options
        @available_effective_date_options = benefit_sponsor_catalogs.map(&:effective_date).map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
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
    end
  end
end
