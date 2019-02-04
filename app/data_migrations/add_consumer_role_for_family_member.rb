require File.join(Rails.root, "lib/mongoid_migration_task")

class AddConsumerRoleForFamilyMember < MongoidMigrationTask
  def migrate
      begin
        family_member_id = ENV['family_member_id'].to_s
        is_applicant= ENV['is_applicant'].to_s
        family_member= FamilyMember.find(family_member_id)
        if family_member.nil? 
          puts "no family member was found with given id for #{family_member_id}" unless Rails.env.test?
        elsif family_member.person.nil?
          puts "no person exist with family member with given id for #{family_member_id}" unless Rails.env.test?
        elsif family_member.person.consumer_role.present?
          puts "consumer role already exist for  family member with given id for #{family_member_id}" unless Rails.env.test?
        end
        if family_member.person.consumer_role.blank?
            puts "creating consumer role for #{family_member.person.full_name}" unless Rails.env.test?
            Factories::EnrollmentFactory.add_consumer_role(
              person: family_member.person, 
              new_is_incarcerated: 'false',
              new_is_state_resident: true,
              new_is_applicant: is_applicant,
              new_citizen_status: "us_citizen"
              )
        end
      rescue Exception => e
        puts "Exception #{e} occured for family #{family.e_case_id}" unless Rails.env.test?
      end
  end
end
