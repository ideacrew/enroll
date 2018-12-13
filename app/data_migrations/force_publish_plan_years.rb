require File.join(Rails.root, "lib/mongoid_migration_task")

class ForcePublishPlanYears < MongoidMigrationTask

    
    def migrate
      start_on_date = Date.strptime(ENV['start_on_date'].to_s, "%m/%d/%Y")
      current_date = Date.strptime(ENV['current_date'].to_s, "%m/%d/%Y")
      puts 'Reverting plan years...' unless Rails.env.test?
      revert_plan_years(start_on_date, current_date) # setting renewing published plan years back to renewing draft
      puts 'Assigning packages...' unless Rails.env.test?
      assign_packages(start_on_date, current_date) #assign benefit packages to census employeess missing them    
      puts'Setting back oe dates...' unless Rails.env.test?
      set_back_oe_date(start_on_date, current_date) #set back oe dates for renewing draft employers with OE dates greater than current date 
      puts 'Force Publishing...' unless Rails.env.test?
      force_publish(start_on_date, current_date) # force publish
      puts 'Generating error CSV of ERs with PYs not in Renewing Enrolling for some reason... ' unless Rails.env.test?
      clean_up(start_on_date, current_date)#create error csv file with ERs that did not transition correctly
      completion_check(start_on_date, current_date)  unless Rails.env.test?
    end
  
    def plan_years_in_aasm_state(aasm_states, start_on_date)
      Organization.where({
        :'employer_profile.plan_years' =>
          { :$elemMatch => {
            :start_on => start_on_date,
            :aasm_state.in => 
              aasm_states
          }}
        })
    end
    
    def revert_plan_years(start_on_date, current_date)
      puts "----renewing published count == #{plan_years_in_aasm_state(['renewing_published'], start_on_date).count} prior to reverting----" unless Rails.env.test?
      plan_years_in_aasm_state(['renewing_published'], start_on_date).each do |org|
        py = org.employer_profile.plan_years.where(aasm_state: 'renewing_published').first
        if py.may_revert_renewal?
          py.revert_renewal!
          py.update_attributes!(open_enrollment_start_on: current_date)
        end
      end
      puts "----renewing published count == #{plan_years_in_aasm_state(['renewing_published'], start_on_date).count} after reverting----" unless Rails.env.test?
      puts "----renewing draft count == #{plan_years_in_aasm_state(['renewing_draft'], start_on_date).count} after reverting plan years" unless Rails.env.test?
    end
    
    def assign_packages(start_on_date, current_date)
        CSV.open("#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
        csv << ["Organization.fein", "Organization.legal_name", "Census_Employee", "ce_id"]
        plan_years_in_aasm_state(['renewing_draft'], start_on_date).each do |org|
          py = org.employer_profile.renewing_plan_year
          if py.application_errors.present?
            org.employer_profile.census_employees.each do |ce|
              if ce.benefit_group_assignments.where(:benefit_group_id.in => py.benefit_groups.map(&:id)).blank?
                unless ce.aasm_state == "employment_terminated" || ce.aasm_state == "rehired"
                  data = [org.fein, org.legal_name, ce.full_name, ce.id]  
                  csv << data
                  ce.try(:save!)
                end
              end
            end
            puts "#{org.fein} has errors #{py.application_errors}" if py.application_errors.present? unless Rails.env.test?
          end
        end
      end 
      puts "Unnasigned packages file created" unless Rails.env.test?
    end
  
    def set_back_oe_date(start_on_date, current_date)
      puts "Setting back OE dates for the below ERs" unless Rails.env.test?
      plan_years_in_aasm_state(['renewing_draft'], start_on_date).each do |org|
        py = org.employer_profile.plan_years.where(aasm_state: 'renewing_draft').first
        if py.open_enrollment_start_on > current_date
          puts "#{org.legal_name}" unless Rails.env.test?
          py.update_attributes!(open_enrollment_start_on: current_date)
          py.save!
        end
      end
    end
  
    def force_publish(start_on_date, current_date)
      puts "----Renewing draft count == #{plan_years_in_aasm_state(['renewing_draft'], start_on_date).count} prior to publish" unless Rails.env.test?
      plan_years_in_aasm_state(['renewing_draft'], start_on_date).each do |org|
        py = org.employer_profile.renewing_plan_year
        org.employer_profile.renewing_plan_year.force_publish! if py.may_force_publish? && py.is_application_valid?
      end
      puts "----Renewing draft count == #{plan_years_in_aasm_state(['renewing_draft'], start_on_date).count} after publish" unless Rails.env.test?
      puts "----Renewing enrolling count == #{plan_years_in_aasm_state(['renewing_enrolling'], start_on_date).count} after publish" unless Rails.env.test?
    end
    
    def clean_up(start_on_date, current_date)
      CSV.open("#{Rails.root}/employers_not_in_renewing_enrolling_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
      csv << ["Organization", "Plan Year State"]
      plan_years_in_aasm_state(['renewing_draft','renewing_publish_pending','renewing_enrolled','renewing_published'], start_on_date).each do |org|
          aasm_state = org.employer_profile.plan_years.where(start_on: start_on_date).first.aasm_state
          data = [org.fein, aasm_state]
          csv << data
        end
      end
    end
  
    def query_enrollment_count(start_on_date, current_date)
      feins = plan_years_in_aasm_state(['renewing_enrolling'], start_on_date).pluck(:fein)
      clean_feins = feins.map do |f|
        f.gsub(/\D/,"")
      end
      qs = Queries::PolicyAggregationPipeline.new
      qs.filter_to_shop.filter_to_active.filter_to_employers_feins(clean_feins).with_effective_date({"$gt" => (start_on_date - 1.day)}).eliminate_family_duplicates
      enroll_pol_ids = []
      excluded_ids = []
      qs.evaluate.each do |r|
        enroll_pol_ids << r['hbx_id']
      end
      enroll_pol_ids.count
    end
  
    def completion_check(start_on_date, current_date)
      while true 
        before = query_enrollment_count(start_on_date, current_date)
        puts " before = #{before}"  unless Rails.env.test?
        sleep 60  
        after = query_enrollment_count(start_on_date, current_date)
        puts " after = #{after}"  unless Rails.env.test?
        if before == after 
          puts 'Renewals complete'  unless Rails.env.test?
          return
        end
      end
    end
   end
  
  
  