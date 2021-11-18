# Migration for fixin gnil maine counties

# Run this with RAILS_ENV=production bundle exec rake migrations:fix_maine_nil_counties

namespace :migrations do
  desc "Fix Mil Maine Counties"
  task :fix_maine_nil_counties, [:file] => :environment do |task, args|
    # - find families missing county
    # - update county for single county
    # - list the county with nil county with zip outside ME
    # - application county update

    #1 list people with nil county
    def pull_county
      puts("Beginning pull counties")
      file_name = "#{Rails.root}/list_county.csv"
      people = Person.all.where(:addresses.exists => true, :"addresses.county".in => [nil, ""])
      total_count = people.count
      users_per_iteration = 10_000.0
      counter = 0
      number_of_iterations = (total_count / users_per_iteration).ceil
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "zip"]
        while counter < number_of_iterations
          offset_count = users_per_iteration * counter
          output = people.no_timeout.offset(offset_count).each do |person|
            address = person.rating_address
            county = address&.county
            csv << [person.hbx_id, address&.zip] if county.nil?
            counter += 1
          end
        end
      end
    end
    pull_county


    def address_needs_fixing?(address)
      address.county.blank? && !address.zip.blank?
    end

    def address_fixer(address)
      counties = county_finder(address.zip)
      if counties.count == 1
        address.county = counties.first
        :fixed
      elsif counties.count == 0
        puts "No county found for ZIP: #{address.zip} #{address.state}"
        :no_county_found
      else
        puts "Multiple counties found for ZIP: #{address.zip} #{address.state}"
        :multiple_counties_found
      end
    end

    def county_finder(zip)
      ::BenefitMarkets::Locations::CountyZip.where(zip: zip)
    end

    #2 update people with nil county
    def update_county
      puts("Beginning update counties")
      file_name = "#{Rails.root}/update_county.csv"
      people = Person.all.where(:addresses.exists => true, :"addresses.county".in => [nil, ""])
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "zip", "status"]
        output = people.no_timeout.each do |person|
          puts "Examining Person: #{person.hbx_id} #{person.full_name} - consumer: #{person.consumer_role.blank?.inspect}"
          counters = {}
          counters[:person] = { fixed: 0, no_county_found: 0, multiple_counties_found: 0, no_fix_needed: 0 }
          person.addresses.each do |address|
            if address_needs_fixing?(address)
              result = address_fixer(address)
              counters[:person][result] += 1
            else
              counters[:person][:no_fix_needed] += 1
            end
          end

          counters[:faa_apps] = { fixed: 0, no_county_found: 0, multiple_counties_found: 0, no_fix_needed: 0 }
          if person.primary_family.present?
            applications = FinancialAssistance::Application.where(family_id: person.primary_family.id, aasm_state: "draft")
            applications.each do |application|
              application.applicants.each do |applicant|
                applicant.addresses.each do |address|
                  if address_needs_fixing?(address)
                    result = address_fixer(address)
                    counters[:faa_apps][result] += 1
                  else
                    counters[:faa_apps][:no_fix_needed] += 1
                  end
                end
              end
            end
          end
          csv << [person.hbx_id, person.addresses.first.zip, "updated #{counters.inspect}"]
          #rescue StandardError => e
          #  csv << [person.hbx_id, person_address&.zip, "StandardError: #{e}"]
          #end
        end
      end
    end
    update_county
  end
end