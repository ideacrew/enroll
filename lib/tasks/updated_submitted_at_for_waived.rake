namespace :correction do
  desc "corrected submitted at date for waived plan"
  task :updated_submitted_at_for_waived, [:first_name, :last_name, :encrypted_ssn, :hbx_id, :submitted_at] => :environment do |task, args|
  	person = Person.where(first_name: args[:first_name], last_name: args[:last_name], encrypted_ssn: args[:encrypted_ssn]).first
  	submitted_at = Time.parse(args[:submitted_at])
    waived_plan = person.primary_family.active_household.hbx_enrollments.waived.to_a.first
    waived_plan.submitted_at = submitted_at
    waived_plan.save
    puts "Populating submitted at for waived enrollment of #{args[:first_name]} #{args[:last_name]}."
  end
end
