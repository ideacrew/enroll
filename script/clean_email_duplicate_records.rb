#get all people who has more that one email records
people_more_than_one_email = Person.all.select{|person| person.emails.count > 1}


#clean all duplicates by kind and address
people_more_than_one_email.each do |person|
  begin
    person.emails = person.emails.uniq{|email| email.kind && email.address}
    person.save!
    person.reload
  rescue => e
    puts "Error Person id #{person.id}" + e.message
  end
end