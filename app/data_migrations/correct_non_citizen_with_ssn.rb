require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root, "app/data_migrations/correct_citizen_with_ssn")

class CorrectNonCitizenStatus < CorrectCitizenStatus
  def get_people
    Person.where("consumer_role.lawful_presence_determination.ssa_responses.received_at" => {"$gte" => Time.mktime(2016,7,5,8,0,0)},
                 "consumer_role.lawful_presence_determination.vlp_authority" => {"$ne" => "curam"},
                 "consumer_role.lawful_presence_determination.citizen_status" => {"$ne" => "us_citizen"},
                 "encrypted_ssn" => {"$ne" => nil})
  end

  def parse_ssa_response(person)
    response_doc = get_response_doc(person)
    doc = Nokogiri::XML(response_doc.body)
    ssn_response = doc.xpath("//ns1:ssn_verified").first ? doc.xpath("//ns1:ssn_verified").first.content : nil
    citizenship_response = doc.xpath("//ns1:citizenship_verified").try(:first) ? doc.xpath("//ns1:citizenship_verified").first.content : nil
    if ssn_response && ssn_response == "true"
      citizenship_response && citizenship_response == "true" ? person.consumer_role.ssn_valid_citizenship_valid!(args) : person.consumer_role.ssn_valid_citizenship_invalid!(args)
    else
      person.consumer_role.ssn_invalid!(args)
    end
  end

  def migrate
    people_to_fix = get_people
    people_to_fix.each do |person|
      move_to_pending_ssa(person)
      person.reload
      parse_ssa_response(person)
    end
  end
end