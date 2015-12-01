namespace :update_consumer_role do
  desc "update applicant_id in consumer_role by family_member"
  task :applicant => :environment do 
    puts "*"*80
    puts "updating applicant_id of consumer_role by family_member"

    Family.all.each do |family|
      family.family_members.each do |member|
        if member.person.present? and member.person.consumer_role.present?
          consumer_role = member.person.consumer_role
          consumer_role.update(applicant_id: member.id)
        end
      end
    end

    puts "complete"
    puts "*"*80
  end
end
