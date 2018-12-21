require File.join(Rails.root, "lib/mongoid_migration_task")

class DeactivateSpecialEnrollmentPeriod < MongoidMigrationTask
	def migrate
		person = Person.where(hbx_id: ENV['person_hbx_id']).first
		primary_family = person.primary_family
		sep=primary_family.special_enrollment_periods.find(ENV['sep_id'])
		if person.nil?
			puts "no person was found with given hbx_id #{ENV['person_hbx_id']}" unless Rails.env.test?
		elsif primary_family.nil?
			puts "no family was found for person with given hbx_id #{ENV['person_hbx_id']}" unless Rails.env.test?
		elsif sep.nil?
			puts "no SEP was found with given sep_id #{ENV['sep_id']}" unless Rails.env.test?
		elsif !sep.is_active?
			puts "The SEP with id #{ENV['sep_id']} is already inactive"
		else
			end_date = sep.start_on
			sep.update_attributes!(end_on:end_date)
			if sep.is_active?
				puts "The SEP with id #{ENV['sep_id']} can not be deactivated"
			else
				puts "The SEP with id #{ENV['sep_id']} has been deactivated"
			end
		end
	end
end

