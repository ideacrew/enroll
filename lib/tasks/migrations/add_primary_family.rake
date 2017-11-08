##To run rake task: RAILS_ENV=production bundle exec rake person:update dep_hbx_id="123456789"
namespace :person do
  desc "update person"
  task :update, [:hbx_id] => :environment do |task, args|
    begin
    	dep_hbx_id = args[:hbx_id]
		person = Person.where(hbx_id: dep_hbx_id).last
		family = Family.new
		primary_applicant = family.add_family_member(person, is_primary_applicant: true) unless family.find_family_member_by_person(person)
		person.relatives.each do |related_person|
			family.add_family_member(related_person)
		end
		family.family_members.map(&:__association_reload_on_person)
		family.save!
    rescue Exception => e
     	puts e.message
    end
  end
end
