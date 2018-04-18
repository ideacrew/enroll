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

      def benefit_sponsorship
        @form_mapping.benefit_sponsorship
      end

      def calculate_start_on_options
        calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end

      def effective_period
        start_on..end_on
      end

      def open_enrollment_period
        open_enrollment_start_on..open_enrollment_end_on
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
    end
  end
end
