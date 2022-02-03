# Migration for fixin gnil maine counties
require File.join(Rails.root, "app", "helpers", "me_county_helper")
include MeCountyHelper

# Run this with RAILS_ENV=production bundle exec rake migrations:fix_maine_nil_counties
namespace :migrations do
  desc "Fix Mil Maine Counties"
  task :fix_maine_nil_counties, [:file] => :environment do |task, args|
    # - find families missing county
    # - update county for single county
    # - list the county with nil county with zip outside ME
    # - application county update

    def people
      people_1_ids = Person.all.where(:addresses.exists => true, :"addresses.county".in => [nil, "", /\w.*\s.*\w/]).map(&:_id)
      # benefitmarkets because previously we erroneously assigned a object instead of ring to county
      people_2_ids = Person.where("addresses.county" => /.*benefitmarkets.*/i).map(&:_id)
      people_ids = (people_1_ids + people_2_ids).flatten
      Person.where(:"_id".in => people_ids)
    end

    #1 list people with nil county
    def pull_county
      puts("Beginning pull counties")
      file_name = "#{Rails.root}/list_county.csv"
      total_count = people.count
      users_per_iteration = 10_000.0
      counter = 0
      number_of_iterations = (total_count / users_per_iteration).ceil
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "zip", "county"]
        while counter < number_of_iterations
          offset_count = users_per_iteration * counter
          output = people.no_timeout.offset(offset_count).each do |person|
            address = person.rating_address
            county = address&.county
            unless ::BenefitMarkets::Locations::RatingArea.rating_area_for(address)
              csv << [person.hbx_id, address&.zip, county]
            end
            counter += 1
          end
        end
      end
    end
    pull_county

    def address_needs_fixing?(address)
      return false if address.zip.blank?
      address.county.blank? || address.county.downcase.include?("benefitmarket") || (address.county.split(" ").length > 1) || !!(address.county =~ /county/i)
    end

    def address_fixer(address)
      zip = address.zip.match(/^(\d+)/).captures.first # incase of 20640-2342 (9 digit zip)
      # Must be titleized like "Presque Isle" or "Bangor"
      town_name = address.city.titleize
      county_name = find_specific_county(town_name)
      counties = county_finder(zip)
      if counties.count == 1
        address.county = counties.first.county_name
        address.save!
        :fixed
      elsif county_name.present?
        address.county = county_name
        address.save!
        puts("Successfully resolved county by town for #{town_name}")
        :fixed
      elsif !!(address.county =~ /county/i)
        puts "removed word 'county' from county name #{address.county}"
        address.county = county_county_remover(address.county)
        address.save!
        :fixed
      elsif counties.count == 0
        puts "No county found for ZIP: #{zip} #{address.state}"
        :no_county_found
      else
        puts "Unable to resolve multiple counties found for ZIP: #{zip} #{address.state}"
        :multiple_counties_found
      end
    end

    def county_county_remover(county)
      # This removes the word 'county' from county name
      county.gsub(/ county/i, '')
    end

    def county_finder(zip)
      ::BenefitMarkets::Locations::CountyZip.where(zip: zip)
    end
    
    
    # Will return a county name otherwise nil
    def find_specific_county(town_name)
      maine_counties_and_towns.detect { |key, value| maine_counties_and_towns[key].include?(town_name) }&.first
    end

    #2 update people with nil county
    def update_county
      puts("Beginning update counties")
      file_name = "#{Rails.root}/update_county.csv"
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
            applications = FinancialAssistance::Application.where(family_id: person.primary_family.id, :"aasm_state".in => ["draft", "submitted"])
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
              application.save if application.changed?
            end
          end

          person.save if person.changed?
          csv_comment = counters.to_s.gsub!(",", "")
          csv << [person.hbx_id, person.addresses.first.zip, csv_comment]
          #rescue StandardError => e
          #  csv << [person.hbx_id, person_address&.zip, "StandardError: #{e}"]
          #end
        end
      end
    end
    update_county
  end
end





