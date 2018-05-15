namespace :recurring do
  desc "An automation rake task that sends out dependent age off termination notifications to congressional and non congressional employees"
  task employee_dependent_age_off_termination: :environment do
    new_date = TimeKeeper.date_of_record
    if new_date.mday == 1
      Family.all_with_multiple_family_members.by_enrollment_shop_market.each do |family|
        begin
          primary_person = family.primary_applicant.person
          employee_roles = primary_person.active_employee_roles
          employee_roles.each do |employee_role|
            next if (employee_role.benefit_group.nil?)
            ben_grp = employee_role.benefit_group.is_congress
            enrollments = employee_role.census_employee.active_benefit_group_assignment.hbx_enrollments
            enrollments.select{|e| (HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES).include?(e.aasm_state)}
            if enrollments.present?
              covered_members = enrollments.inject([]) do |covered_members, enrollment|
                covered_members += enrollment.hbx_enrollment_members.map(&:family_member).map(&:person)
              end.uniq
              covered_members_ids = covered_members.flat_map(&:_id)
              relations = primary_person.person_relationships.select{ |rel| (covered_members_ids.include? rel.relative_id) && (rel.kind == "child")}
              if relations.present?
                aged_off_dependents = relations.select{|dep| (new_date.month == (dep.relative.dob.month)) && (dep.relative.age_on(new_date.end_of_month) >= 26)}.flat_map(&:relative)
                next if aged_off_dependents.empty?
                dep_hbx_ids = aged_off_dependents.map(&:hbx_id)
                event_name = ben_grp ? "employee_dependent_age_off_termination_congressional" : "employee_dependent_age_off_termination_non_congressional"
                ShopNoticesNotifierJob.perform_later(employee_role.census_employee.id.to_s, event_name, dep_hbx_ids: dep_hbx_ids )
                puts "Delivered employee_dependent_age_off_termination notice to #{employee_role.census_employee.full_name}" unless Rails.env.test?
              end
            end
          end
        rescue => e
          Rails.logger.error {"Unable to deliver employee_dependent_age_off_termination notice to: #{family.primary_applicant.person.hbx_id} due to #{e.backtrace}"}
        end
      end
    end
  end
end