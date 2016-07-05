# Rake task to Fix existing records which have phone number data but for which full_phone_number is blank
# To run rake task: rake migrations:update_full_phone_number
namespace :migrations do
  desc "update full phone number if nil? in person and organization office locations"
  task :update_full_phone_number => :environment do
    count = 0
    # collect phones of a person for which full phone number is nil
    person_phones = Person.where(:'phones'.exists=>true).where(:"phones.full_phone_number".exists => false).map(&:phones).flatten.compact
    # collect phone of office location for which full phone number is nil
    office_phones = Organization.where(:'office_locations.phone'.exists=>true).where(:"office_locations.phone.full_phone_number".exists =>false).
                    map(&:office_locations).flatten.map(&:phone).flatten.compact
    phones = person_phones + office_phones
    phones.each do |phone|
      phone.update_attribute(:full_phone_number, phone.to_s)
      count += 1
    end
    puts "updated #{person_phones.count} full phone number for persons"
    puts "updated #{office_phones.count} full phone number for office locations"
  end
end
