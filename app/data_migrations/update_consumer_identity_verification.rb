require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConsumerIdentityVerification < MongoidMigrationTask
  def migrate
    begin
      hbx_ids = "#{ENV['hbx_id']}".split(',').uniq
      hbx_ids.each do |hbx_id|
        person = Person.where(hbx_id: hbx_id).first 
        unless person.present?
          puts "No person record is found with #{hbx_id}"
        else
          person.consumer_role.update_attributes!(bookmark_url:"/insured/interactive_identity_verifications/service_unavailable") if person.consumer_role.identity_validation == "pending"
          puts "Updated bookmark URL on consumer" unless Rails.env.test?
        end
      end
    rescue => e
      e.message
    end
  end
end

