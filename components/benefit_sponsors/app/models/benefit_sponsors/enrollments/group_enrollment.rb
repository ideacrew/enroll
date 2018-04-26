module BenefitSponsors
  class Enrollments::GroupEnrollment

    attr_accessor :coverage_start_on, :product, :previous_product, :pricing_model_kind,
                  :product_cost_total, :benefit_sponsor, :contribution_model_kind,
                  :sponsor_contribution_total, :member_enrollments, :group_id

    def initialize
      @group_id                   = nil
      @coverage_start_on          = nil
      @product                    = nil
      @previous_product           = nil 

      @pricing_model_kind         = nil
      @product_cost_total         = 0.00

      @benefit_sponsor            = nil
      @contribution_model_kind    = nil
      @sponsor_contribution_total = 0.00

      @member_enrollments         = []
    end


  end
end
