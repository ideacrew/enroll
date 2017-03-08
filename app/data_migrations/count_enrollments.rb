require File.join(Rails.root, "lib/migration_task")

class CountEnrollments < MigrationTask 

  def get_counts
    orgs = Organization.where('employer_profile' => {"$exists" => true})
    a = TimeKeeper.datetime_of_record
    orgs.no_timeout.each {|org|
      latest_plan_year = org.employer_profile.latest_plan_year
      if latest_plan_year
        b = TimeKeeper.datetime_of_record
        latest_plan_year.update_attributes(enrolled_summary: latest_plan_year.total_enrolled_count, waived_summary: latest_plan_year.waived_count)
        puts "Count #{latest_plan_year.waived_count}, #{TimeKeeper.datetime_of_record - b}"
      end
    }
    puts "Done #{TimeKeeper.datetime_of_record - a}"
  end
end