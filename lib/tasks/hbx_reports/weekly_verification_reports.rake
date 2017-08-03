require 'csv'
 # These are the weekly reports of the people who cleared verifications in the last week & people who added new documents
 # The task to run is RAILS_ENV=production bundle exec rake reports:cleared_verifications_or_added_new_documents
namespace :reports do
  desc "Weekly list of households with verifications that have been cleared since the last week"

  task :cleared_verifications_or_added_new_documents => :environment do

    start_date = TimeKeeper.date_of_record - 7.days
    end_date = TimeKeeper.date_of_record

    verified_count = 0
    people_with_new_docs_count = 0

    fiels_names_1= %w(
      HbxId
      First_Name
      Last_Name
      Verification_Type_And_Reason
    )

    fiels_names_2= %w(
      HbxId
      First_Name
      Last_Name
      New_Documents_Count
      Verification_Types_Uploaded_Last_Week
    )

    file_name_1 = "#{Rails.root}/public/people_cleared_verification_report.csv"
    file_name_2 = "#{Rails.root}/public/people_uploaded_new_documents_report.csv"

    CSV.open(file_name_1, "w", force_quotes: true) do |row|

      row << fiels_names_1

      def verified_succesfully_in_past_week(role, start_date, end_date)
        event = role.workflow_state_transitions.where(to_state: "fully_verified").first
        (start_date.beginning_of_day..end_date.end_of_day).cover? event.transition_at if event.present?
      end

      people = Person.all_consumer_roles.where({:"consumer_role.workflow_state_transitions.transition_at".gte => start_date.beginning_of_day,
                                                    :"consumer_role.workflow_state_transitions.transition_at".lte => end_date.end_of_day,
                                                      :"consumer_role.workflow_state_transitions.to_state" => "fully_verified"})

      people.each do |person|
        begin
          role = person.consumer_role
          if verified_succesfully_in_past_week(role, start_date, end_date)
            verified_count += 1
            verification_reasons = []
            person.verification_types.each do |v_type|
              verification_reasons <<  case v_type
              when "Social Security Number"
                { v_type => role.ssn_update_reason } if role.ssn_update_reason.present?
              when "American Indian Status"
                { v_type => role.native_update_reason } if role.native_update_reason.present?
              else
                role.lawful_presence_update_reason if role.lawful_presence_update_reason.present?
              end
            end

            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              verification_reasons.compact.uniq
            ]
          end
        rescue Exception => e
          puts "#{e}"
        end
      end

      puts "Total people who cleared verifications in past week size is #{verified_count}"
    end


    CSV.open(file_name_2, "w", force_quotes: true) do |row|
      row << fiels_names_2
      
      def uploaded_in_past_week(doc, start_date, end_date)
        ((start_date.beginning_of_day..end_date.end_of_day).cover? doc.created_at) && doc.identifier.present?
      end

      Person.all_consumer_roles.where(:"consumer_role.vlp_documents.identifier" => {:$exists => true}).each do |person|
        begin
          documents = person.consumer_role.vlp_documents
          docs_uploaded_in_last_week = documents.select { |doc| uploaded_in_past_week(doc, start_date, end_date) }
          if docs_uploaded_in_last_week.present?
            people_with_new_docs_count += 1

            row << [
              person.hbx_id,
              person.first_name,
              person.last_name,
              docs_uploaded_in_last_week.size,
              docs_uploaded_in_last_week.map(&:verification_type)
            ]
          end
        rescue Exception => e
          puts "#{e}"
        end
      end
      puts "Total people who uploaded new documents in the past week size is #{people_with_new_docs_count}"
    end
  end
end
