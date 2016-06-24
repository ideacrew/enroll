namespace :migrations do
  desc "create missing consumer roles for dependents"
  task :dependent_consumer_role_create => :environment do

    Family.all.each do |family|
      begin
        primary = family.primary_applicant.person

        # next if primary.employee_roles.any?
        next if primary.consumer_role.blank?

        coverage_household = family.active_household.immediate_family_coverage_household
        family_members = coverage_household.coverage_household_members.map(&:family_member)
     
        family_members.each do |member|
          if member.person.consumer_role.blank?
            puts "creating consumer role for #{member.person.full_name}"

            Factories::EnrollmentFactory.add_consumer_role(
              person: member.person, 
              new_is_incarcerated: 'false',
              new_is_state_resident: true,
              new_is_applicant: 'false',
              new_citizen_status: "us_citizen"
              )
          end
        end
      rescue Exception => e
        puts "Exception #{e} occured for family #{family.e_case_id}"
      end
    end

  end
end

