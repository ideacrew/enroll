require 'csv'
# RAILS_ENV=production bundle exec rake reports:outstanding_types_created date = "Month,year"  (example: "January, 2018")
namespace :reports do
  desc "Outstanding verifications created monthly report"
  task :outstanding_types_created => :environment do
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME VERIFICATION_TYPE OUTSTANDING DUE_DATE)

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

    def due_date_for_type(person, type, transition)
      if person.consumer_role.special_verifications.any?
        sv = person.consumer_role.special_verifications.select{|sv| sv.verification_type == type }.select{|svp| svp.created_at < transition.transtition_at}
        sv.any? ? sv.due_date : transition.transition_at + 95.days
      else
        transition.transition_at + 95.days
      end
    end

    def get_rejected_type(person)
      record = person.consumer_role.verification_type_history_elements.where(:action => "return for deficiency", :created_at=>{'$gte'=>start_date, '$lte' => end_date}).first
      record.verification_type if record
    end

    def people
      Person.where(:"consumer_role.workflow_state_transitions".elem_match => {
          "$and" => [
              {:event => {"$in" => ["ssn_invalid!",
                                    "ssn_valid_citizenship_invalid!",
                                    "fail_dhs!",
                                    "fail_residency!",
                                    "reject!"] }},
              { :transition_at.gte => start_date },
              { :transition_at.lte => end_date }
          ]
      })
    end

    def workflow_transitions(person)
      person.consumer_role.workflow_state_transitions.where(:event => "reject!", :transition_at=>{'$gte'=>start_date, '$lte' => end_date})
    end

    file_name = "#{Rails.root}/public/outstanding_types_created_#{date.gsub(" ", "").split(",").join("_")}.csv"


    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      people.each do |person|
        workflow_transitions(person).to_a.each do |transition|
          case transition.event
            when "ssn_invalid!"
              type = "Social Security Number"
            when "ssn_valid_citizenship_invalid!"
              type = (person.verification_types - ['DC Residency', 'Social Security Number', 'American Indian Status']).first
            when "fail_dhs!"
              type = "Immigration status"
            when "fail_residency!"
              type = "DC Residency"
            when "reject!"
              type = get_rejected_type(person)
          end


          csv << [
              subscriber_id(person),
              person.hbx_id,
              person.first_name,
              person.last_name,
              type,
              "outstanding",
              due_date_for_type(person, type, transition).to_date
          ]
        end
      end
      puts "*********** DONE ******************"
    end

  end
end


