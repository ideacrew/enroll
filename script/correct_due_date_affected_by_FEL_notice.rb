family = Family.where(min_verification_due_date:Date.new(2019,2,10))
family.each do |f|
  message = f.primary_person.inbox.messages.where(subject:"Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance")
   unless message.first.nil? 
      if message.last.created_at > Date.new(2018,11,17)
           f.update_attributes(min_verification_due_date:Date.new(2018,11,1))
      end
   end
end


