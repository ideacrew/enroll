namespace :update_shop do
  desc "Renewing employer benefit period"
  task :enroll_employer_profile => :environment do
    changed_count = 0

    effective_date = Date.new(2016,1,1)
    organizations = Organization.all_employers_by_plan_year_start_on(effective_date)

    employers = organizations.map(&:employer_profile).inject({}) do |employers, profile|
      employers[profile.legal_name] = profile.fein
      employers
    end

    # employers = {
    #    # "Member-US House of Rep." => "536002522"
    # # #   "STAFF US House of Representatives" => "536002523",
    # # #   "United States Senate" => "536002558",
    # # #   # "YFU International Educational" => "260005055"
    # "fusionSpan" => "273950719"
    # }

    
    employers.each do |name, fein|

      begin
        puts "Processing employer: #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        # Congress : is_congress flag

        renewal_factory = Factories::PlanYearEnrollFactory.new
        renewal_factory.employer_profile = employer
        renewal_factory.start_on = effective_date
        renewal_factory.enroll
        changed_count += 1
      rescue => e
        puts e.to_s
      end
    end

    puts "Processed #{employers.count} employers, renewed #{changed_count} employers"
  end
end