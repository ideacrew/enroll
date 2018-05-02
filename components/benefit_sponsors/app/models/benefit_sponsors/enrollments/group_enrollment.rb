module BenefitSponsors
  class Enrollments::GroupEnrollment
    include ActiveModel::Model

    attr_accessor :coverage_start_on, :product, :previous_product,
                  :product_cost_total, :benefit_sponsor,
                  :sponsor_contribution_total, :member_enrollments, :group_id,
                  :rating_area,
                  :rate_schedule_date

    def initialize(opts = {})
      @group_id                   = nil
      @coverage_start_on          = nil
      @product                    = nil
      @previous_product           = nil 

      @product_cost_total         = 0.00

      @benefit_sponsor            = nil
      @sponsor_contribution_total = 0.00

      @member_enrollments         = []
      @rate_schedule_date = nil
      @rating_area = nil
      super(opts)
    end

    def remove_members_by_id!(member_id_list)
      @member_enrollments = @member_enrollments.reject do |m_en|
        member_id_list.include?(m_en.member_id)
      end
      self
    end

  end
end
