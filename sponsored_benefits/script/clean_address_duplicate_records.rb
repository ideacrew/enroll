#get all people who has more that one address records including different kinds as home and work
people_more_than_one_address = Person.all.select{|person| person.addresses.count > 1}

#clean all duplicates by kind and address
people_more_than_one_address.each do |person|
  begin
    person.addresses = person.addresses.uniq{|address| address.kind && address.address_1 && address.address_2}
    person.save!
    person.reload
  rescue => e
    puts "Error Person id #{person.id}" + e.message
  end
end