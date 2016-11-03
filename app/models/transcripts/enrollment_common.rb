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
        }).order_by(:effective_on.asc)
        .select{|e| e.plan.active_year == enrollment.plan.active_year}
        .reject{|en| en.subscriber.hbx_id != enrollment.subscriber.hbx_id}
    end

    def matching_shop_coverages(enrollment, family=nil)

      if enrollment.persisted?
        assignment = enrollment.benefit_group_assignment
        benefit_group = (assignment.present? ? assignment.benefit_group : enrollment.benefit_group)
        if benefit_group.blank?
          id_list = []
        else
          id_list = benefit_group.plan_year.benefit_groups.collect(&:_id).uniq
        end
      else
        # TODO: Fix this for Conversion ER
        plan_year = enrollment.employer_profile.find_plan_year_by_effective_date(enrollment.effective_on)
        id_list = plan_year.benefit_groups.collect(&:_id).uniq if plan_year.present?
      end

      family ||= enrollment.family
      return [] if family.blank? || id_list.blank?

      family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).where({
        :coverage_kind => enrollment.coverage_kind, 
        :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
        }).order_by(:effective_on.asc)
        .reject{|en| en.subscriber.hbx_id != enrollment.subscriber.hbx_id}
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