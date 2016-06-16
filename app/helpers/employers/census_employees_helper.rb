module Employers::CensusEmployeesHelper

  def ce_enrollments_to_display
    enrollments = []
    enrollments += enrollments_for_bg_assignment(@benefit_group_assignment) if @benefit_group_assignment.present?
    enrollments += enrollments_for_bg_assignment(@renewal_benefit_group_assignment) if @renewal_benefit_group_assignment.present?
    enrollments.compact
  end

  def enrollments_for_bg_assignment(bg_assignment)
    enrollments = []
    coverages = bg_assignment.hbx_enrollments
    enrollments << coverages.detect{|enrollment| enrollment.coverage_kind == 'health'}
    enrollments << coverages.detect{|enrollment| enrollment.coverage_kind == 'dental'}
    enrollments
  end
end