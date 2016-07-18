require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectCitizenStatus < MongoidMigrationTask
  def get_people
    Person.where("consumer_role.lawful_presence_determination.ssa_responses.received_at" => {"$gte" => Time.mktime(2016,7,5,8,0,0)},
                 "consumer_role.lawful_presence_determination.vlp_authority" => {"$ne" => "curam"},
                 "consumer_role.lawful_presence_determination.citizen_status" => "us_citizen",
                 "encrypted_ssn" => {"$ne" => nil})
  end

  def move_to_pending_ssa(person)
    begin
      person.consumer_role.aasm_state = "ssa_pending"
      person.save!
    rescue => e
      puts "Error for Person id: #{person.id}. Error: #{e.message}"
    end
  end

  def get_response_doc(person)
    person.consumer_role.lawful_presence_determination.ssa_responses.where('received_at' => {"$gte" => Time.mktime(2016,7,5,8,0,0)}).first
  end

  def get_previous_response(person)
    person.consumer_role.lawful_presence_determination.ssa_responses.where('received_at' => {"$lt" => Time.mktime(2016,7,5,8,0,0)}).first
  end

  def parse_ssa_response(person)
    response_doc = get_response_doc(person)
    doc = Nokogiri::XML(response_doc.body)
    ssn_response = doc.xpath("//ns1:ssn_verified").try(:first) ? doc.xpath("//ns1:ssn_verified").first.content : nil
    citizenship_response = doc.xpath("//ns1:citizenship_verified").try(:first) ? doc.xpath("//ns1:citizenship_verified").first.content : nil
    if ssn_response && ssn_response == "true"
      citizenship_response && citizenship_response == "true" ? person.consumer_role.ssn_valid_citizenship_valid!(args) : person.consumer_role.ssn_valid_citizenship_invalid!(args)
    else
      check_previous_response(person)
    end
  end

  def check_previous_response(person)
    response_doc = get_previous_response(person)
    if response_doc
      doc = Nokogiri::XML(response_doc.body)
      ssn_response = doc.xpath("//ns1:ssn_verified").first.content
      citizenship_response = doc.xpath("//ns1:citizenship_verified").try(:first) ? doc.xpath("//ns1:citizenship_verified").first.content : nil
      if ssn_response && ssn_response == "true"
        citizenship_response && citizenship_response == "true" ? person.consumer_role.ssn_valid_citizenship_valid!(args) : person.consumer_role.ssn_valid_citizenship_invalid!(args)
      else
        person.consumer_role.ssn_invalid!(args)
      end
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

  def args
    OpenStruct.new(:determined_at => Time.mktime(2016,7,5,8,0,0), :vlp_authority => 'ssa')
  end
end
