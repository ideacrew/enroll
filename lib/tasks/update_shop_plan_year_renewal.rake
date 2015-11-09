namespace :update_shop do
  desc "Renewing employer benefit period"
  task :plan_year_renewal => :environment do 
    changed_count = 0

    employers = {
      # "RehabFocus LLC" => "711024079",
      # "Hooks Solutions LLC" => "331138193",
      # "Don Ciccio & Figli" => "263057381",
      # # "Elevate Interval Fitness LLC" => "463256626",
      # "Garner & Associates LLC" => "2735787
      # "Set Sports Physical Therapy PLLC" => "010887598",
      # "ICWA" => "131621044",
      # "Game Change LLC" => "460937444",
      # "ADW Capital Management, LLC" => "471516657",
      # "NSight365 LLC" => "465732698",
      # "The New LeDroit Park Building Company" => "454467977",
      # "Hattie Ruttenberg" => "133712482",
      # "Cap 8 Doors & Hardware" => "455162389",
      # "District Restaurant Group" => "274667942",
      # "GWHCC" => "223860377",
      # "Arab Center Washington DC" => "464736138",
      # "Morales Public Relations" => "462817580",
      # "Alter Modus International Corporation" => "260376753",
      # "Annie's Ace Hardware" => "272665426",
      # "Arturo Ardila-Gomez" => "451474721"
      
      "Member-US House of Rep." => "536002522",

    }

    employers.each do |name, fein|
      begin
        puts "Processing employer: #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        # Set ER to correct state from data migration
        # employer.employer_enrolled! if employer.binder_paid?

        # clear existing renewing plan years and benefit group assignments
        employer.plan_years.renewing.each do |plan_year|
          benefit_group_ids = plan_year.benefit_groups.map(&:id)
          puts "Deleting renewal plan year reference from CensusEmployees"
          CensusEmployee.by_benefit_group_ids(benefit_group_ids).each do |census_employee|
            census_employee.renewal_benefit_group_assignment.destroy
          end
          plan_year.destroy
        end

        renewal_factory = Factories::PlanYearRenewalFactory.new
        renewal_factory.employer_profile = employer
        renewal_factory.is_congress = true
        renewal_factory.renew
        changed_count += 1
      rescue => e
        puts e.to_s
      end
    end

    puts "Processed #{employers.count} employers, renewed #{changed_count} employers"
  end

  desc "Auto renew employees enrollments"
  task :family_enrollment_renewal => :environment do

    employers = {
      # "RehabFocus LLC" => "711024079",
      # "Hooks Solutions LLC" => "331138193",
      # "Don Ciccio & Figli" => "263057381",
      # # "Elevate Interval Fitness LLC" => "463256626",
      # "Garner & Associates LLC" => "273578793",
      # "Set Sports Physical Therapy PLLC" => "010887598",
      # "ICWA" => "131621044",
      # "Game Change LLC" => "460937444",
      # "ADW Capital Management, LLC" => "471516657",
      # "NSight365 LLC" => "465732698",
      # "The New LeDroit Park Building Company" => "454467977",
      # "Hattie Ruttenberg" => "133712482",
      # "Cap 8 Doors & Hardware" => "455162389",
      # "District Restaurant Group" => "274667942",
      # "GWHCC" => "223860377",
      # "Arab Center Washington DC" => "464736138",
      # "Annie's Ace Hardware" => "272665426",
      # "Arturo Ardila-Gomez" => "451474721",
      # "Morales Public Relations" => "462817580",
      # "Alter Modus International Corporation" => "260376753",

      "Member-US House of Rep." => "536002522",
      # "STAFF US House of Representatives" => "536002523",
      # "United States Senate" => "536002558",

    }

    employers.each do |name, fein|
      begin
        puts "Processing employer: #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        changed_count = 0
        family_missing = 0

        employer.census_employees.non_terminated.each do |ce|
          person = Person.where(encrypted_ssn: Person.encrypt_ssn(ce.ssn)).first
          if person.blank?
            employee_role, family = Factories::EnrollmentFactory.add_employee_role(
                                                                                    first_name: ce.first_name,
                                                                                    last_name: ce.last_name,
                                                                                    ssn: ce.ssn, 
                                                                                    dob: ce.dob,
                                                                                    employer_profile: employer,
                                                                                    gender: ce.gender,
                                                                                    hired_on: ce.hired_on
                                                                                  )
            puts "created person record for #{ce.full_name}"
          end

          family = person.primary_family if family.blank?

        #   if family.blank?
        #     Factories::EnrollmentFactory.build_employee_role(
        #        person, false, employer, ce, ce.hired_on
        # )
        #   end

          if family.nil?
            puts "family missing for #{ce.full_name}"
            family_missing += 1
          else
          # if family.enrollments.any?
            puts "  renewing: #{ce.full_name}"
            factory = Factories::FamilyEnrollmentRenewalFactory.new
            factory.family = family
            factory.census_employee = ce
            factory.renew

            changed_count += 1
            puts "  renewed: #{ce.full_name}"
          end
        end

        # families = employer.census_employees.inject([]) do |families, ce|
        #   person = Person.where(encrypted_ssn: Person.encrypt_ssn(ce.ssn)).first
        #   if person.blank?
        #     families
        #   else
        #     families << person.primary_family
        #   end
        # end

        # changed_count = 0

        # families.compact.each do |family|
        #   if family.enrollments.any?
        #     puts "  renewing: #{family.primary_family_member.full_name}"
        #     factory = Factories::FamilyEnrollmentRenewalFactory.new
        #     factory.family = family
        #     factory.renew

        #     changed_count += 1
        #     puts "  renewed: #{family.primary_family_member.full_name}"
        #   else
        #     puts "  no active enrollments for: #{family.primary_family_member.full_name}"
        #   end
        # end
      rescue => e
        puts e.to_s
      end
      puts "Processed #{employer.census_employees.non_terminated.count} census employees, renewed #{changed_count} families, missing #{family_missing} families"
    end

  end
end
