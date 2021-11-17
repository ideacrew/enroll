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
      people = Person.all.where(:addresses.exists => true, :"addresses.county" => nil)
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


    #2 update people with nil county
    def update_county
      puts("Beginning update counties")
      file_name = "#{Rails.root}/update_county.csv"
      people = Person.all.where(:consumer_role.exists => true, :addresses.exists => true, :"addresses.county" => nil)
      total_count = people.count
      users_per_iteration = 10_000.0
      counter = 0
      number_of_iterations = (total_count / users_per_iteration).ceil
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "zip", "status"]
        while counter < number_of_iterations
          offset_count = users_per_iteration * counter
          output = people.no_timeout.offset(offset_count).each do |person|
            address = person.rating_address
            county = address&.county
            next if county.present?
            next if person.consumer_role.blank?

            county_objs = ::BenefitMarkets::Locations::CountyZip.where(zip: address.zip)
            if county_objs.count == 1
              begin
                address.update_attributes!(county: county_objs[0].county_name)
                applications = FinancialAssistance::Application.where(family_id: person.primary_family.id, aasm_state: "draft")
                applications.each do |application|
                   application.applicants.each do |applicant|
                     applicant_address = applicant.addresses.where(kind: "home").first
                     applicant_address.update_attributes(county: county_objs[0].county_name)
                   end
                end
                person.person_create_or_update_handler
                csv << [person.hbx_id, address&.zip, "updated"]
              rescue StandardError => e
                csv << [person.hbx_id, address&.zip, "StandardError: #{e}"]
              end
            elsif county_objs.count > 1
              csv << [person.hbx_id, address&.zip, "multiple county for matching zip"]
            elsif county_objs.count == 0
              csv << [person.hbx_id, address&.zip, "zip outside me"]
            end
            counter += 1
          end
        end
      end
    end
    update_county


    #3 list people by counties with nil county for testing purpose

    @one_county = 0
    @zero_county = 0
    @many_county = 0

    def update_county
      puts("Beginning update counties")
      file_name = "#{Rails.root}/update_county.csv"
      people = Person.all.where(:addresses.exists => true, :"addresses.county" => nil)
      total_count = people.count
      users_per_iteration = 10_000.0
      counter = 0
      number_of_iterations = (total_count / users_per_iteration).ceil
      CSV.open(file_name, 'w+', headers: true) do |csv|
        csv << ["person_hbx_id", "zip", "status"]
        while counter < number_of_iterations
          offset_count = users_per_iteration * counter
          output = people.no_timeout.offset(offset_count).each do |person|
            address = person.rating_address
            county = address&.county
            next if county.present?
            next if person.consumer_role.blank?

            county_objs = ::BenefitMarkets::Locations::CountyZip.where(zip: address.zip)
            if county_objs.count == 1
              csv << [person.hbx_id, address&.zip, "updated"]
              @one_county += 1
            elsif county_objs.count > 1
              csv << [person.hbx_id, address&.zip, "multiple county for matching zip"]
              @many_county += 1
            elsif county_objs.count == 0
              csv << [person.hbx_id, address&.zip, "zip outside me"]
              @zero_county += 1
            end
            counter += 1
          end
        end
        puts "zero_county: #{@zero_county} | many_county: #{@many_county}| one_county: #{@one_county}"
      end
    end
    update_county
  end
end