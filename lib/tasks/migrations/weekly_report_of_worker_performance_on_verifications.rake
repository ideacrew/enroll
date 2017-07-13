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
      Action_Date
    )

    file_name = "#{Rails.root}/public/worker_performance_report.csv"

    CSV.open(file_name, "w", force_quotes: true) do |row|

      row << fiels_names

      people = Person.all_consumer_roles.where({:"consumer_role.workflow_state_transitions.user_id"=>{:$exists=>true}, 
                                                    :"consumer_role.workflow_state_transitions.to_state"=>"fully_verified", 
                                                      :"consumer_role.workflow_state_transitions.transition_at".gte => start_date.beginning_of_day, 
                                                        :"consumer_role.workflow_state_transitions.transition_at".lte => end_date.end_of_day})

      people.each do |person|

        begin
          wfst = person.consumer_role.workflow_state_transitions.where({:"user_id"=>{:$exists=>true}, 
                                                                          :"to_state"=>"fully_verified", 
                                                                            :"transition_at".gte => start_date.beginning_of_day, 
                                                                              :"transition_at".lte => end_date.end_of_day}).first
          if wfst.present?
            admin_user = User.find(wfst.user_id)
            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              admin_user.person.full_name,
              wfst.transition_at
            ]
          end
        rescue Exception => e
          puts "#{e}"
        end
      end
    end
  end
end