require File.join(Rails.root, "lib/mongoid_migration_task")
class RemoveDocumentsAssociatedToPerson < MongoidMigrationTask
  def migrate
    hbx_id = ENV['hbx_id']
    person = Person.by_hbx_id(hbx_id).first
    if person.present? 
      message = person.inbox.messages.where(id: ENV['message_id'].to_s).first rescue nil
      if person.present? 
        message.destroy!
      puts "successfully removed document and message" unless Rails.env.test?
      end
    end
  end
end
