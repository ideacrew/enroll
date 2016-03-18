namespace :migrations do
  desc "Update OE dates renewing employers"
  task :update_oe_dates_for_renewing_employers => :environment do

    organizations = Organization.where(:"employer_profile.plan_years" => { 
      :$elemMatch => {
        :"start_on".in => [Date.new(2016, 5, 1), Date.new(2016, 6, 1)],
        :"aasm_state" => 'renewing_draft'
      }
    })

    puts "Found #{organizations.size} 5/1, 6/1 employers with renewing_draft"
    count = 0
    organizations.each do |organization|
      renewing = organization.employer_profile.plan_years.renewing
      if renewing.size > 1
        puts "Found more than 1 renewing plan year"
        next
      end
      renewing_plan_year = renewing.first
      renewing_plan_year.update_attributes(:open_enrollment_start_on => renewing_plan_year.start_on - 2.months)
      count += 1 
    end
    puts "Updated #{count} employers."
  end
end