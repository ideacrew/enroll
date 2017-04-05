require 'csv'
# This is a one-time report
# The task to run is RAILS_ENV=production rake reports:family:family_list_with_antiquated_relationships
namespace :reports do
  namespace :family do
    desc "List of family_with_antiquated_relationships"
    task :family_list_with_antiquated_relationships => :environment do
      field_names  = %w(
           Family_E_Case_ID
           Primary_family_member_first_name
           Primary_family_member_last_namer
           Primary_family_member_hbx_id
           Member_first_name
           Member_last_name
           Member_hbx_id
           Member_relationship_to_primary_member
         )
      count = 0
      file_name = "#{Rails.root}/public/family_list_with_antiquated_relationships.csv"
      CSV.open(file_name, "w", force_quotes: true) do |csv|
        csv << field_names
        people_id=Person.collection.aggregate([{"$match"=>{"person_relationship.kind"=>{"$in"=>["ward","guardian","other_tax_dependent"]}}},
                                             {"$group"=>{"_id"=>"$_id"}}]).to_a

        people_id.each do |person_id|
          person=Person.find(person_id[:_id])
          unless person.person_relationships.size <= 1
            person.person_relationships.each do |relationship|
            if ["guardian", "ward" ,"other_tax_dependent"].include? relationship.kind
              csv << [
                        person.primary_family.e_case_id,
                        person.first_name,
                        person.last_name,
                        person.hbx_id,
                        relationship.relative.first_name,
                        relationship.relative.last_name,
                        relationship.relative.hbx_id,
                        relationship.kind
                        ]
              count += 1
            end
            end
          end
        end
      end
      puts "Total case with antiquated relationships  is #{count}"
    end
  end
end
