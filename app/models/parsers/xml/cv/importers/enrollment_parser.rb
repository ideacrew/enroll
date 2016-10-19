module Parsers::Xml::Cv::Importers
  class EnrollmentParser
    attr_reader :policy, :enrollment

    def initialize(input_xml)
      @policy = Openhbx::Cv2::Policy.parse(input_xml, single: true)
      @enrollment = @policy.policy_enrollment
    end

    def get_enrollment_object
      kind = enrollment.individual_market.present? ? 'individual' : 'employer_sponsored'
      individual_market = enrollment.individual_market
      elected_aptc_pct = individual_market.present? ? individual_market.elected_aptc_percent.to_f : 0
      applied_aptc_amount = individual_market.present? ? individual_market.applied_aptc_amount.to_f : 0
      employee_role = get_employee_role_by_shop_market_xml(enrollment.shop_market)
      if e_plan = enrollment.plan
        metal_level = e_plan.metal_level.strip.split("#").last
        coverage_type = e_plan.coverage_type.strip.split("#").last
        plan = Plan.new(
          id: e_plan.id,
          hios_id: e_plan.id,
          name: e_plan.name,
          active_year: e_plan.active_year,
          metal_level: metal_level,
          coverage_kind: coverage_type,
          ehb: e_plan.ehb_percent.to_f,
          #plan_type: ,
        )
      end
      hbx_enrollment_members = []
      policy.enrollees.each do |enrollee|
        hbx_enrollment_members << HbxEnrollmentMember.new(
          is_subscriber: enrollee.is_subscriber == 'true',
          coverage_start_on: enrollee.benefit.begin_date,
          coverage_end_on: enrollee.benefit.end_date,
          premium_amount: enrollee.benefit.premium_amount,
          #applied_aptc_amount: , # can not find it in xml
        )
      end
      HbxEnrollment.new(
        #hbx_id: ,
        kind: kind,
        elected_aptc_pct: elected_aptc_pct,
        applied_aptc_amount: applied_aptc_amount,
        plan: plan,
        carrier_profile_id: enrollment.plan.try(:carrier).try(:id),
        #writing_agent_id: broker_link.id,
        #terminated_on: ,
        coverage_kind: enrollment.plan.try(:coverage_type),
        #enrollment_kind: ,
        #count_of_members: policy.enrollees.length,
        hbx_enrollment_members: hbx_enrollment_members,
      )
    end

    def get_employee_role_by_shop_market_xml(shop_market)
      return nil #if shop_market.blank?
    end
  end
end
