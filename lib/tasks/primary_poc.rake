namespace :primary do
  desc "Makes a staff member a primary poc if staff count is 1"
  # Run with rake primary:poc
  task :poc => [:environment] do
    orgs = Organization.no_timeout.where("employer_profile" => {"$exists" => true})
    
    orgs.each do |o|
      employer = o.employer_profile
      staff = Person.staff_for_employer_including_pending(employer)
      if staff.count == 1
        staff.first.make_primary(true)
      end
    end
    puts "Primary POC are set"
  end
end