require 'csv'
 # These are the weekly reports of worker performance on verifications
 # The task to run is RAILS_ENV=production bundle exec rake reports:worker_performance
namespace :reports do
  desc "Weekly report of worker performance on verifications at family member level"

  task :worker_performance => :environment do

    start_date = TimeKeeper.date_of_record - 7.days
    end_date = TimeKeeper.date_of_record

    fiels_names= %w(
      HbxId
      First_Name
      Last_Name
      Admin_User
      Admin_User_HBX_ID
      Action_Date
      Action
      Types-Reasons
    )

    file_name = "#{Rails.root}/public/worker_performance_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |row|

      row << fiels_names

      count = 0

      people = Person.all_consumer_roles.where({:"consumer_role.workflow_state_transitions.user_id"=>{:$exists=>true}, 
                                                  :"consumer_role.workflow_state_transitions.transition_at".gte => start_date.beginning_of_day,
                                                    :"consumer_role.workflow_state_transitions.transition_at".lte => end_date.end_of_day,
                                                      :"$or" => [{:"consumer_role.workflow_state_transitions.to_state" => "fully_verified"},
                                                        {:"consumer_role.workflow_state_transitions.to_state" => "verification_outstanding",
                                                          :"consumer_role.workflow_state_transitions.event" => "reject!"}]})

      people.each do |person|

        begin
          wfsts = person.consumer_role.workflow_state_transitions.where({:"user_id"=>{:$exists=>true},
                                                                          :"transition_at".gte => start_date.beginning_of_day,
                                                                            :"transition_at".lte => end_date.end_of_day,
                                                                            :"$or" => [{:"to_state" => "fully_verified"},
                                                                              {:"to_state" => "verification_outstanding",
                                                                                :"event" => "reject!"}]})
          if wfsts.present?
            types_reasons = []
            role = person.consumer_role
            person.verification_types.each do |v_type|
              types_reasons <<  case v_type
                                when "Social Security Number"
                                  { v_type => role.ssn_update_reason } if role.ssn_update_reason.present?
                                when "American Indian Status"
                                  { v_type => role.native_update_reason } if role.native_update_reason.present?
                                else
                                  role.lawful_presence_update_reason if role.lawful_presence_update_reason.present?
                                end
            end
            wfsts.each do |wfst|
              count += 1
              admin_user = User.find(wfst.user_id)
              row << [
                person.hbx_id,
                person.first_name,
                person.last_name,
                admin_user.person.full_name,
                admin_user.person.hbx_id,
                wfst.transition_at,
                (wfst.event || "Verify"),
                types_reasons.compact.uniq
              ]
            end
          end
        rescue Exception => e
          puts "#{e}"
        end
      end
      puts "Total count of records: #{count}"
    end
  end
end
