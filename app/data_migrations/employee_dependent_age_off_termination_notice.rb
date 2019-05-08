require File.join(Rails.root, "lib/mongoid_migration_task")

class EmployeeDependentAgeOffTerminationNotice < MongoidMigrationTask

  def migrate
    hbx_ids = ENV['hbx_ids'].split(' ').uniq
    hbx_ids.each do |hbx_id|
      begin
        primary_person = Person.where(:hbx_id => hbx_id).first
        trigger_dep_age_off_notice(primary_person)
      rescue => e
        puts "unable to trigger dependent age off termination notice to person with hbx_id #{hbx_id} due to #{e.backtrace}" unless Rails.env.test?
      end
    end
  end

  def trigger_dep_age_off_notice(person)
    new_date = TimeKeeper.date_of_record
    employee_roles = person.active_employee_roles
    employee_roles.each do |employee_role|
      benefit_group = employee_role.benefit_group
      next if benefit_group.nil?
      hbx_enrollments = employee_role.census_employee.active_benefit_group_assignment.hbx_enrollments
      enrollments = hbx_enrollments.select{|e| (HbxEnrollment::ENROLLED_AND_RENEWAL_STATUSES).include?(e.aasm_state)}
      if enrollments.present?
        covered_members = enrollments.inject([]) do |covered_members, enrollment|
          covered_members += enrollment.hbx_enrollment_members.map(&:family_member).map(&:person)
        end.uniq
        covered_members_ids = covered_members.flat_map(&:_id)
        relations = person.person_relationships.select{ |rel| (covered_members_ids.include? rel.relative_id) && (rel.kind == "child")}
        if relations.present?
          aged_off_dependents = relations.select{|dep| (new_date.month == (dep.relative.dob.month)) && (dep.relative.age_on(new_date.end_of_month) >= 26)}.flat_map(&:relative)
          next if aged_off_dependents.empty?
          dep_hbx_ids = aged_off_dependents.map(&:hbx_id)
          event_name = benefit_group.is_congress? ? 'employee_notice_dependent_age_off_termination_congressional' : 'employee_notice_dependent_age_off_termination_non_congressional'
          observer = Observers::NoticeObserver.new
          observer.deliver(recipient: employee_role, event_object: employee_role.census_employee, notice_event: event_name,  notice_params: {dep_hbx_ids: dep_hbx_ids})
          puts "Delivered employee_dependent_age_off_termination notice to #{employee_role.census_employee.full_name}" unless Rails.env.test?
        end
      end
    end
  end
end
