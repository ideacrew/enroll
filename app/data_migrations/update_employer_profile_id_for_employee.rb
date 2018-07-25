require File.join(Rails.root, "lib/mongoid_migration_task")
class UpdateEmployerProfileIdForEmployee< MongoidMigrationTask
  def migrate
    begin
      organization_fein = ENV["organization_fein"]
      employee_role_id = ENV["employee_role_id"]

      employer_profile_id = ::BenefitSponsors::Organizations::Organization.where(fein: organization_fein).first.employer_profile.id.to_s
      employee_role = Person.all_employee_roles.where(:"employee_roles._id" => BSON::ObjectId.from_string(employee_role_id)).first.employee_roles.find employee_role_id

      if employer_profile_id && employee_role
        employee_role.update_attributes!(benefit_sponsors_employer_profile_id: employer_profile_id)
        puts "Successfully updated employee_role with benefit_sponsors_employer_profile_id: #{employer_profile_id}" unless Rails.env.test?
      else
        puts "Couldnot find employer_profile_id and/or employee_role with the given fein: #{organization_fein}, employer_role_id: #{employee_role_id}" unless Rails.env.test?
      end
    rescue => e
      puts "error: #{e.backtrace}" unless Rails.env.test?
    end
  end
end
