module BenefitSponsors
  module Forms
    class BenefitApplicationForm

      extend ActiveModel::Naming
      include ActiveModel::Conversion
      include ActiveModel::Validations
      include Virtus.model

      attribute :start_on, Date
      attribute :end_on, Date
      attribute :open_enrollment_start_on, Date
      attribute :open_enrollment_end_on, Date
      attribute :fte_count, Integer
      attribute :pte_count, Integer
      attribute :msp_count, Integer

      validates :start_on, presence: true
      validates :end_on, presence: true
      validates :open_enrollment_start_on, presence: true
      validates :open_enrollment_end_on, presence: true

      # validates :validate_application_dates

      delegate :benefit_sponsorship, :benefit_application, to: :@benefit_application_service

      def initialize(params = {})
        @benefit_application_service = BenefitSponsors::Services::BenefitApplicationService.new(params)
        super
      end

      def load_attributes_from_resource
        if benefit_application.present?
          self.assign_attributes(@benefit_application_service.attributes_to_virtus_params)
        end
      end

      # Forms cannot be persisted
      def persisted?
        false
      end

      def save
        if valid?
          persist!
        else
          false
        end
      end
    
      def validate_application_dates
        if start_on <= end_on
          errors.add(:start_on, "can't be later than end on date")
        end
      end

      def scheduler
        return @scheduler if defined? @scheduler
        @scheduler = ::BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new
      end

      def calculate_start_on_options
        scheduler.calculate_start_on_dates.map {|date| [date.strftime("%B %Y"), date.to_s(:db) ]}
      end
    
      def start_on=(date)
        super(date.to_date)
      end

      def is_start_on_valid?
        start_on_result[:result] == "ok"
      end

      def start_on_result
        scheduler.check_start_on(start_on)
      end

      def open_enrollment_dates
        scheduler.calculate_open_enrollment_date(start_on) if is_start_on_valid?
      end

      def enrollment_schedule
        scheduler.shop_enrollment_timetable(start_on) if is_start_on_valid?
      end

      private 

      def persist!
        @benefit_application_service.store!(self)
      end
    end
  end
end
