module BenefitSponsors
  class Enrollments::MemberEnrollment

    attr_accessor :member_id, :converage_eligibility_on, :product_price,
                  :sponsor_contribution

    def initialize
      @member_id = nil
      @converage_eligibility_on = nil
      @product_price            = 0.00
      @sponsor_contribution     = 0.00
    end

  end
end
