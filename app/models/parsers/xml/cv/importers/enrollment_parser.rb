module Parsers::Xml::Cv::Importers
  class EnrollmentParser
    attr_reader :policy, :enrollment

    def initialize(input_xml)
      @policy = Openhbx::Cv2::Policy.parse(input_xml, single: true)
      @enrollment = @policy.policy_enrollment
    end

    def get_enrollment_object
      kind = @enrollment.individual_market.present? ? 'individual' : 'employer_sponsored'
      individual_market = @enrollment.individual_market
      elected_aptc_pct = individual_market.present? ? individual_market.elected_aptc_percent.to_f : 0
      applied_aptc_amount = individual_market.present? ? individual_market.applied_aptc_amount.to_f : 0
      #if shop_market = @enrollment.shop_market
        #employer = EmployeeRole.new(name: shop_market.employer.name, dba: shop_market.employer.dba)
      #end
      if e_plan = enrollment.plan
        metal_level = e_plan.metal_level.strip.split("#").last
        coverage_type = e_plan.coverage_type.strip.split("#").last
        plan = Plan.new(
          id: e_plan.id,
          name: e_plan.name,
          active_year: e_plan.active_year,
          metal_level: metal_level,
          coverage_kind: coverage_type,
          ehb: e_plan.ehb_percent.to_f,
        )
      end
      HbxEnrollment.new(
        kind: kind,
        elected_aptc_pct: elected_aptc_pct,
        applied_aptc_amount: applied_aptc_amount,
        plan: plan,
      )
    end
  end
end
