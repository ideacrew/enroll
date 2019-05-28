require File.join(Rails.root, "lib/mongoid_migration_task")

class ForcePublishPlanYears < MongoidMigrationTask

    
    def migrate
      start_on_date = Date.strptime(ENV['start_on_date'].to_s, "%m/%d/%Y")
      current_date = Date.strptime(ENV['current_date'].to_s, "%m/%d/%Y")
      if ENV['only_assign_packages'] == "true"
        puts 'Assigning packages and creating unassigned packages csv...'
        assign_packages(start_on_date, current_date)
      elsif ENV['reports_only'] == "true"
        puts 'Creating detail and non-detail report...'
        detail_report(start_on_date)
        non_detail_report(start_on_date)
      elsif ENV['detail_report_only'] == "true"
        puts 'Creating detail report...'
        detail_report(start_on_date)
      elsif ENV['query_count_only'] == "true"
        puts "Enrollment count is #{query_enrollment_count(start_on_date, current_date)}"
      else
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
                unless ce.aasm_state == "employment_terminated" || ce.aasm_state == "rehired" ||  ce.aasm_state == "cobra_terminated"
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

    def non_detail_report(start_on_date)
      orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => start_on_date, :aasm_state.in => PlanYear::RENEWING}})

      CSV.open("#{Rails.root}/monthly_renewal_employer_enrollment_report_#{start_on_date.strftime('%m_%d')}.csv", "w") do |csv|
        csv << [
          "Employer Legal Name",
          "Employer FEIN",
          "Renewal State",
          "#{start_on_date.prev_year.year} Active Enrollments",
          "#{start_on_date.prev_year.year} Passive Renewal Enrollments"
        ]

        orgs.each do |organization|

          puts "Processing #{organization.legal_name}"

          employer_profile = organization.employer_profile

          data = [
            employer_profile.legal_name,
            employer_profile.fein,
            employer_profile.renewing_plan_year.aasm_state.camelcase
          ]
          next if employer_profile.active_plan_year.blank?

          active_bg_ids = employer_profile.active_plan_year.benefit_groups.pluck(:id)
          families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES}})

          if employer_profile.renewing_plan_year.present?
            if employer_profile.renewing_plan_year.renewing_enrolling? || employer_profile.renewing_plan_year.renewing_enrolled?
              renewal_bg_ids = employer_profile.renewing_plan_year.benefit_groups.pluck(:id)
            end
          end

          active_enrollment_count = 0
          renewal_enrollment_count = 0

          families.each do |family|

            enrollments = family.active_household.hbx_enrollments.where({
              :benefit_group_id.in => active_bg_ids,
              :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
            })

            %w(health dental).each do |coverage_kind|
              if enrollments.where(:coverage_kind => coverage_kind).present?
                active_enrollment_count += 1
              end
            end

            if renewal_bg_ids.present?
              renewal_enrollments = family.active_household.hbx_enrollments.where({
                :benefit_group_id.in => renewal_bg_ids,
                :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
              })

              %w(health dental).each do |coverage_kind|
                if renewal_enrollments.where(:coverage_kind => coverage_kind).present?
                  renewal_enrollment_count += 1
                end
              end
            end
          end

          data += [active_enrollment_count, renewal_enrollment_count]
          csv << data
        end
      end
    end 

    start_on_date  = Date.new(2019,7,1)
    system ("rm -rf '#{Rails.root}/detail_report_#{start_on_date.strftime('%m_%d')}.csv'")

    def detail_report(start_on_date)
      orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => start_on_date, :aasm_state.in => PlanYear::RENEWING}})
  
      CSV.open("#{Rails.root}/detail_report_#{start_on_date.strftime('%m_%d')}.csv", "w") do |csv|
      csv << [
        "Employer Legal Name",
        "Employer FEIN",
        "Employer HBX ID",
        "Renewal State",
        "First name",
        "Last Name",
        "Roster status",
        "Hbx ID",
        "#{start_on_date.prev_year.year} enrollment", 
        "#{start_on_date.prev_year.year} plan", 
        "#{start_on_date.prev_year.year} effective_date",
        "#{start_on_date.prev_year.year} enrollment kind",
        "#{start_on_date.prev_year.year} status",
        "#{start_on_date.year} enrollment", 
        "#{start_on_date.year} plan", 
        "#{start_on_date.year} effective_date",
        "#{start_on_date.year} enrollment kind",
        "#{start_on_date.year} status",
        "Failure Reason"
      ]
    orgs.each do |organization|
        puts "Processing #{organization.legal_name}"
        employer_profile = organization.employer_profile
        next if employer_profile.active_plan_year.blank?
        active_bg_ids = employer_profile.active_plan_year.benefit_groups.pluck(:id)
        families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES +  HbxEnrollment::WAIVED_STATUSES}})

        if employer_profile.renewing_plan_year.present?
          if employer_profile.renewing_plan_year.renewing_enrolling? || employer_profile.renewing_plan_year.renewing_enrolled?
            renewal_bg_ids = employer_profile.renewing_plan_year.benefit_groups.pluck(:id)
          end
        end

          puts "found #{families.count} families"
          families.each do |family|
            begin
              enrollments = family.active_household.hbx_enrollments.where({
                :benefit_group_id.in => active_bg_ids,
                :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES  +  HbxEnrollment::WAIVED_STATUSES
              })

              employee_role = enrollments.last.employee_role 
              if employee_role.present?
                employee = employee_role.census_employee
              end

              if employee.blank?
                  puts "#{family.id}-----#{family.primary_applicant}" if family.primary_applicant.nil?
                  person = family.primary_applicant.person
                  
                  role = person.employee_roles.detect{|role| role.employer_profile_id.to_s == employer_profile.id.to_s} 
                  employee = role.census_employee
              end

              if renewal_bg_ids.present?
                renewal_enrollments = family.active_household.hbx_enrollments.where({
                  :benefit_group_id.in => renewal_bg_ids,
                  :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']   +  HbxEnrollment::WAIVED_STATUSES
                  })
              end

              employer_employee_data = [
                employer_profile.legal_name,
                employer_profile.fein,
                employer_profile.hbx_id,
                employer_profile.renewing_plan_year.aasm_state.camelcase
              ]

              if employee.present?
                employer_employee_data += [employee.first_name, employee.last_name, employee.aasm_state.humanize, employee_role.try(:person).try(:hbx_id)] 
              else
                employer_employee_data += [nil, nil, nil, nil]
              end

              %w(health dental).each do |coverage_kind|
                next if enrollments.where(:coverage_kind => coverage_kind).blank?
                data = employer_employee_data
                data += enrollment_details_by_coverage_kind(enrollments, coverage_kind).flatten
                if renewal_bg_ids.present?
                  data += enrollment_details_by_coverage_kind(renewal_enrollments, coverage_kind).flatten
                  data += find_failure_reason(renewal_enrollments, coverage_kind, '2019', employer_profile.renewing_plan_year)
                else  
                  data += [nil,nil,nil,nil,nil]
                  data += find_failure_reason(enrollments, coverage_kind, '2018', employer_profile.renewing_plan_year)
                end
                csv << data
              end
            rescue Exception => e
              puts "Failed: #{family.id}#{e.to_s}"
              next
            end
          end
        end
      end
    end


    def enrollment_details_by_coverage_kind(enrollments, coverage_kind)
      enrollment = enrollments.where(:coverage_kind => coverage_kind).sort_by(&:submitted_at).last
      return [] if enrollment.blank?
      data = []

      data =[
        enrollment.hbx_id,
        enrollment.try(:plan).try(:hios_id),
        enrollment.effective_on.strftime("%m/%d/%Y"),
        enrollment.coverage_kind,
        enrollment.aasm_state.humanize ]
      end

    def find_failure_reason(enrollments, coverage_kind, year, plan_year)
      enrollment = enrollments.where(:coverage_kind => coverage_kind).sort_by(&:submitted_at).last
      data = []
      if  enrollment.try(:effective_on).try(:strftime,"%Y") == '2019' &&  enrollment.aasm_state == 'coverage_selected' 
         data += ["A different plan was manually selected for the current year"]
      elsif plan_year.aasm_state == 'renewing_enrolled' 
        data += ["The plan year was manually published by stakeholders"]
      elsif plan_year.aasm_state == 'renewing_published_pending' 
        data += ["ER zip code is not in DC"]
      elsif year == "2018" &&  enrollment.aasm_state.in?(HbxEnrollment::WAIVED_STATUSES)
        data += ["2018 coverage was not active"]
      else 
        data += [""]
      end
      data
    end

    detail_report(start_on_date)
   end
  
  
  # ar = ["86545CT1400004","86545CT1400005","86545CT1400003","86545CT1400004","86545CT1400005"]
  # ar.map do |id|
  #   plan = Plan.where(hios_plan_id:id).first 
  #   plan.carrier
  # end.compact