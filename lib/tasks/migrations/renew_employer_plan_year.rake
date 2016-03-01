namespace :migrations do
  desc "update employer address"
  task :renew_employer_plan_year => :environment do

    ["Jubilee Jobs", "MMoore Consulting LLC"].each do |employer_name|
      organization = Organization.where(:legal_name => employer_name).first
      plan_year = organization.employer_profile.active_plan_year
      plan_year.update_attributes(end_on: Date.new(2016, 02, 29))

      organization.employer_profile.plan_years.renewing.each do |plan_year|
        benefit_group_ids = plan_year.benefit_groups.map(&:id)
        puts "Deleting renewal plan year reference from CensusEmployees"
        CensusEmployee.by_benefit_group_ids(benefit_group_ids).each do |census_employee|
          census_employee.renewal_benefit_group_assignment.destroy
        end
        plan_year.destroy
      end

      renewal_factory = Factories::PlanYearRenewalFactory.new
      renewal_factory.employer_profile = organization.employer_profile
      renewal_factory.is_congress = false
      renewal_factory.renew
    end
    
  end
end