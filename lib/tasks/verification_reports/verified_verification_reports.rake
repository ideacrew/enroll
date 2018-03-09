require 'csv'
# RAILS_ENV=production bundle exec rake reports:verified_verification_report date="Month,year"  (example: "January, 2018")
namespace :reports do
  desc "Outstanding verifications created monthly report"
  task :verified_verification_report => :environment do
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME VERIFIED VERIFICATION_TYPE VERIFIED_DATE VERIFICATION_REASON)

    def date
      begin
        ENV["date"].strip         
      rescue
        puts 'Provide report month.'
      end
    end

    def subscriber_id(person)
      if person.primary_family
        person.hbx_id
      else
        person.families.map(&:primary_family_member).map(&:hbx_id).join(',')
      end

    end

    def start_date
      Date.parse(date)
    end

    def end_date
      Date.parse(date).next_month
    end

    def verified_history_elements_with_date_range person
      person.consumer_role.verification_type_history_elements.
      where(created_at:{
        :$gte => start_date,
        :$lte => end_date
       }).where(action: "verify")
    
    end
  
    def admin_action
      people_with_consumer_role = Person.where({ :"consumer_role" => {"$exists" => true}})
    end

    def hub_response person
      events = ["ssn_valid_citizenship_valid!", "ssn_valid", "pass_dhs!", "pass_residency!"]
      person.consumer_role.workflow_state_transitions.
        where(created_at: {
        :$gte => start_date,
        :$lte => end_date
         }).where({:event => {"$in" => events}})

    end


    file_name = "#{Rails.root}/public/verified_verification_report_#{TimeKeeper.date_of_record.strftime("%m_%d_%Y")}.csv"


    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      admin_action.each do |person|
        verified_history_elements_with_date_range(person).each do |v|
        
                csv << [  subscriber_id(person),
                          person.hbx_id,
                          person.first_name,
                          person.last_name,  
                          'yes',
                          v.verification_type,
                          v.created_at,
                          v.update_reason
                        ]
         end  

         hub_response(person).each do |hub|        
          case hub.event
            when "ssn_valid_citizenship_valid!"
              type = (person.verification_types - ['DC Residency', 'Social Security Number', 'American Indian status']).first
            when "ssn_valid!"
              type = person.verification_types - ['DC Residency', 'American Indian status']  
            when "pass_dhs!"
              type = "Immigration status"
            when "pass_residency!"
              type = "DC Residency"    
          end

          csv << [
              subscriber_id(person),
              person.hbx_id,
              person.first_name,
              person.last_name,
              'yes',
              type,
              hub.created_at,
              "Hub Response"
          ]
         end     
      end
      
      puts "*********** DONE ******************"
    end

  end
end

