require File.join(Rails.root, "lib/mongoid_migration_task")

class CorrectDueDateAffectedByFELNotice < MongoidMigrationTask
  def migrate
    begin
      family = Family.where(min_verification_due_date:Date.new(2019,2,10))
      family.each do |fam|
        messages = fam.primary_person.inbox.messages.where(subject:"Reminder - You Must Submit Documents by the Deadline to Keep Your Insurance")
         if messages.present? 
            if messages.last.created_at > Date.new(2018,11,17)
              fam.set_due_date_on_verification_types(Date.new(2019,3,21))
              fam.update_attributes(min_verification_due_date: fam.min_verification_due_date_on_family)
              puts "updated due date for family with primary person #{fam.primary_person.hbx_id}" unless Rails.env.test?
            end
         end
      end
    rescue => e
      e.message
    end
  end
end
