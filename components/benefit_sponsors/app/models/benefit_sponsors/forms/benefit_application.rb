module Forms
  class BenefitApplication
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :start_on, :end_on
    attr_accessor :open_enrollment_start_on, :open_enrollment_end_on
    attr_accessor :fte_count, :pte_count, :msp_count, :benefit_sponsorship
      
    validates :start_on, presence: true
    validates :end_on, presence: true
    validates :open_enrollment_start_on, presence: true
    validates :open_enrollment_end_on, presence: true

    def initialize(params = {})
      assign_application_attributes(params)
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

    def benefit_application
      BenefitSponsors::Factories::BenefitApplicationFactory.call(self, benefit_sponsorship)
    end
  end
end
