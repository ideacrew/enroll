brokers = Person.where("broker_role._id" => {"$exists" => true})

brokers.each do |broker|
  broker.approve!
end
