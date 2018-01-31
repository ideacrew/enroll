#get all people who has more that one phone records
people_more_than_one_phone = Person.all.select{|person| person.phones.count > 1}


#clean all duplicates by kind and number
people_more_than_one_phone.each do |person|
  begin
    person.emails = person.phones.uniq{|phone| phone.kind && phone.number}
    person.save!
    person.reload
  rescue => e
    puts "Error Person id #{person.id}" + e.message
  end
end