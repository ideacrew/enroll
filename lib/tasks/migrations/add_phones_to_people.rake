# This rake task used to update phone records on person.
# RAILS_ENV=production bundle exec rake migrations:add_phones_to_people

namespace "migrations" do
  desc "Adding phone records to people"

  task :add_phones_to_people => :environment do

    phones.each do |k, hash_val|
      begin
        people = Person.where(hbx_id: hash_val["hbx_id"])
        if people.size != 1
          puts "Found more than 1 or No person record"
          next
        end
        person = people.first

        person.phones << Phone.new(hash_val["phone"])
        person.save!
      rescue Exception => e
        puts "Exception #{hash_val["hbx_id"]} : #{e}"
      end
    end
  end
end

def phones
  {
    "record_1" => {
      "hbx_id" => "102186",
      "phone" => {
        "country_code" => "",
        "area_code" => "617",
        "number" => "9053044",
        "extension" => "",
        "full_phone_number" => "6179053044",
        "kind" => "phone main"
      }
    }  
  }
end