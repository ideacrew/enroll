module Transcripts
  module EnrollmentCommon

   
    def self.included(base)
      base.extend ClassMethods
    end

    def matching_ivl_coverages(enrollment, family=nil)
      family ||= enrollment.family

      family.active_household.hbx_enrollments.where({
        :coverage_kind => enrollment.coverage_kind, 
        :kind => enrollment.kind,
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
        }).order_by(:effective_on.asc).select{|e| e.plan.active_year == enrollment.plan.active_year}
    end

    def matching_shop_coverages(enrollment, family=nil)
      assignment = enrollment.benefit_group_assignment
      id_list = assignment.benefit_group.plan_year.benefit_groups.collect(&:_id).uniq
      family ||= enrollment.family

      family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).where({
        :coverage_kind => enrollment.coverage_kind, 
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
        }).order_by(:effective_on.asc)
    end

    def match_person_instance(person)
      @people_cache ||= {}
      return @people_cache[person.hbx_id] if @people_cache[person.hbx_id].present?

      if person.hbx_id.present?
        matched_people = ::Person.where(hbx_id: person.hbx_id)
      end

      if matched_people.blank?
        matched_people = ::Person.match_by_id_info(
            ssn: person.ssn,
            dob: person.dob,
            last_name: person.last_name,
            first_name: person.first_name
          )
      end

      @people_cache[person.hbx_id] = matched_people
      matched_people
    end
  end
end