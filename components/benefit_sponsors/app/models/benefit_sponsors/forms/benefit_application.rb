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

    def assign_application_attributes(atts = {})
      atts.each_pair do |k, v|
        self.send("#{k}=".to_sym, v)
      end
    end

    def build(params)
      assign_application_attributes(params)
      return false unless valid?

      BenefitSponsors::BenefitApplications::BenefitApplicationBuilder.build do |builder|
        builder.set_presenter_object(self)
        builder.set_sponsorhip(benefit_sponsorship)
        builder.add_effective_period
        builder.add_open_enrollment_period
        builder.add_fte_count
        builder.add_pte_count
        builder.add_msp_count
      end
    end

    def effective_period
      start_on..end_on
    end

    def open_enrollment_period
      open_enrollment_start_on..open_enrollment_end_on
    end
  end
end
