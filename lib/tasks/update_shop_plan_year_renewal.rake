namespace :update_shop do
  desc "Renewing employer benefit period"
  task :plan_year_renewal => :environment do 

    employers = {
      "RehabFocus LLC" => "711024079",
      "Hooks Solutions LLC" => "331138193",
      "Don Ciccio & Figli" => "263057381",
      # "Elevate Interval Fitness LLC" => "463256626",
      "Garner & Associates LLC" => "273578793",
      "Set Sports Physical Therapy PLLC" => "010887598",
      "ICWA" => "131621044",
      "Game Change LLC" => "460937444",
      "ADW Capital Management, LLC" => "471516657",
      "NSight365 LLC" => "465732698",
      "The New LeDroit Park Building Company" => "454467977",
      "Hattie Ruttenberg" => "133712482",
      "Cap 8 Doors & Hardware" => "455162389",
      "District Restaurant Group" => "274667942",
      "GWHCC" => "223860377",
      "Arab Center Washington DC" => "464736138",
      "Morales Public Relations" => "462817580",
      "Alter Modus International Corporation" => "260376753",
      "Annie's Ace Hardware" => "272665426",
      "Arturo Ardila-Gomez" => "451474721"
    }

    employers.each do |name, fein|
      begin
        puts "processing #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        # Set ER to correct state from data migration
        employer.employer_enrolled! if employer.binder_paid?

        renewal_factory = Factories::EmployerProfilePlanYearRenewal.new
        renewal_factory.employer_profile = employer
        renewal_factory.renew
      rescue => e
        puts e.to_s
      end
    end
  end

  desc "Auto renew employees enrollments"
  task :family_enrollment_renewal => :environment do
    employers = {
      "RehabFocus LLC" => "711024079",
      "Hooks Solutions LLC" => "331138193",
      "Don Ciccio & Figli" => "263057381",
      # "Elevate Interval Fitness LLC" => "463256626",
      "Garner & Associates LLC" => "273578793",
      "Set Sports Physical Therapy PLLC" => "010887598",
      "ICWA" => "131621044",
      "Game Change LLC" => "460937444",
      "ADW Capital Management, LLC" => "471516657",
      "NSight365 LLC" => "465732698",
      "The New LeDroit Park Building Company" => "454467977",
      "Hattie Ruttenberg" => "133712482",
      "Cap 8 Doors & Hardware" => "455162389",
      "District Restaurant Group" => "274667942",
      "GWHCC" => "223860377",
      "Arab Center Washington DC" => "464736138",
      "Morales Public Relations" => "462817580",
      "Alter Modus International Corporation" => "260376753",
      "Annie's Ace Hardware" => "272665426",
      "Arturo Ardila-Gomez" => "451474721"
    }

    employers.each do |name, fein|
      begin
        puts "processing #{name}"
        employer = EmployerProfile.find_by_fein(fein)
        if employer.blank?
          puts "  ** employer not found"
          next
        end

        families = employer.census_employees.inject([]) do |families, ce|
          person = Person.where(encrypted_ssn: Person.encrypt_ssn(ce.ssn)).first
          if person.blank?
            return families
          end
          families << person.primary_family
        end

        families.each do |family|
          next unless family.enrollments.any?
          factory = Factories::FamilyEnrollmentRenewalFactory.new
          factory.family = family
          factory.renew
          puts "renewed...#{family.primary_family_member.full_name}"
        end
      rescue => e
        puts e.to_s
      end
    end
  end
end
