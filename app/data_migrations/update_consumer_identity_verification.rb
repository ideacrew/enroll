require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateConsumerIdentityVerification < MongoidMigrationTask
  def migrate
    begin
      hbx_ids = "#{ENV['hbx_id']}".split(',').uniq
      hbx_id = hbx_ids.each do |hbx_id|
        person = Person.where(hbx_id).first if person.present?
        if person.consumer_role.identity_validation == "pending"
          person.consumer_role.update_attributes!(bookmark_url:"/insured/interactive_identity_verifications/service_unavailable")
          puts "Updated bookmark URL on consumer"
        end
      end
    rescue => e
      e.message
    end
  end
end

