Person.where(
  "consumer_role" => {"$exists" => true, "$ne" => nil},
  "consumer_role.aasm_state" => "fully_verified",
  "consumer_role.lawful_presence_determination_vlp_authority" => {"$in" => ["ssa", "curam"]}
).update_all("$set" => {"consumer_role.lawful_presence_determination.citizenship_result" => "us_citizen"})

Person.where(
  "consumer_role" => {"$exists" => true, "$ne" => nil},
  "consumer_role.aasm_state" => "verification_outstanding"
).update_all("$set" => {"consumer_role.lawful_presence_determination.citizenship_result" => "not_lawfully_present_in_us"})

Person.where(
  "consumer_role" => {"$exists" => true, "$ne" => nil},
  "consumer_role.aasm_state" => "fully_verified",
  "consumer_role.lawful_presence_determination_vlp_authority" => {"$in" => ["dhs"]}
).each do |pers|
  lpd = pers.consumer_role.lawful_presence_determination
  lpd.update_attributes!(:citizenship_result => lpd.citizenship_status)
end
