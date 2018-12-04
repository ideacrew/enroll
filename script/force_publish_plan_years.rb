class ForcePublishPlanYears
  
  def initialize(publish_date, current_date)  
    @publish_date = publish_date
    @current_date = current_date
  end
  
  def call 
    puts 'reverting plan years...' unless Rails.env.test?
    revert_plan_years #revert plan years that are in renewing_published to renewing_draft and set back their OE start dates    
    puts 'assigning packages...' unless Rails.env.test?
    assign_packages #assign benefit packages to census employeess missing them    
    puts'setting back oe date.s..' unless Rails.env.test?
    set_back_oe_date #set back oe dates for renewing draft employers with OE dates greater than current date 
    puts 'force publishing...' unless Rails.env.test?
    force_publish # force publish
    puts '...generating error CSV of ERs with PYs not in Renewing Enrolling for some reason... ' unless Rails.env.test?
    clean_up #create error csv file with ERs that did not transition correctly
  end

  def plan_years_in_aasm_state(aasm_states)
    aasm_states = aasm_states.map do |state|
      {:aasm_state => "#{state}"}
    end
    Organization.where({
      :'employer_profile.plan_years' =>
        { :$elemMatch => {
          :start_on => @publish_date,
          :$or => 
            aasm_states
        }}
      })
  end
  
  def revert_plan_years
    puts "----renewing published count == #{plan_years_in_aasm_state(['renewing_published']).count} prior to reverting----" unless Rails.env.test?
    plan_years_in_aasm_state(['renewing_published']).each do |org|
      py = org.employer_profile.plan_years.where(aasm_state: 'renewing_published').first
      if py.may_revert_renewal?
        py.revert_renewal!
        py.update_attributes!(open_enrollment_start_on: @current_date)
      end
    end
    puts "----renewing published count == #{plan_years_in_aasm_state(['renewing_published']).count} after reverting----" unless Rails.env.test?
    puts "----renewing draft count == #{plan_years_in_aasm_state(['renewing_draft']).count} after reverting plan years" unless Rails.env.test?
  end
  
  def assign_packages
    CSV.open("#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
      csv << ["Org", "Employee"]
      force.plan_years_in_aasm_state(['renewing_draft']).each do |org|
        py = org.employer_profile.renewing_plan_year
        if py.application_errors.present?
          org.employer_profile.census_employees.each do |ce|
            if ce.benefit_group_assignments.where(:benefit_group_id.in => py.benefit_groups.map(&:id)).blank?
              puts "#{ce.full_name}"
              # data = [org./fein, ce.full_name]  
              # csv << data 
              # ce.try(:save!)
            end
          end
          puts "#{org.fein} has errors #{py.application_errors}" if py.application_errors.present?
        end
      end
    end 
  end

  def set_back_oe_date
    plan_years_in_aasm_state(['renewing_draft']).each do |org|
      py = org.employer_profile.plan_years.last
      if py.open_enrollment_start_on > @current_date
        puts "#{org.legal_name}"
        py.update_attributes!(open_enrollment_start_on: @current_date)
        py.save!
      end
    end
  end

  def force_publish
    puts "----renewing draft count == #{plan_years_in_aasm_state(['renewing_draft']).count} prior to publish" unless Rails.env.test?
    plan_years_in_aasm_state(['renewing_draft']).each do |org|
      py = org.employer_profile.renewing_plan_year
      org.employer_profile.renewing_plan_year.force_publish! if py.may_force_publish? && py.is_application_valid?
    end
    puts "----renewing draft count == #{plan_years_in_aasm_state(['renewing_draft']).count} after publish" unless Rails.env.test?
    puts "----renewing enrolling count == #{plan_years_in_aasm_state(['renewing_enrolling']).count} after publish" unless Rails.env.test?
  end
  
  def clean_up
    CSV.open("#{Rails.root}/employers_not_in_renewing_enrolling_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
    csv << ["Organization", "Plan Year State"]
    plan_years_in_aasm_state(['renewing_draft','renewing_publish_pending','renewing_enrolled','renewing_published']).each do |org|
        aasm_state = org.employer_profile.plan_years.last.aasm_state
        data = [org.fein, aasm_state]
        csv << data
      end
    end
  end

  def query_enrollment_count 

    feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => @publish_date, :aasm_state => 'renewing_enrolling'}}).pluck(:fein)

    clean_feins = feins.map do |f|
      f.gsub(/\D/,"")
    end

    qs = Queries::PolicyAggregationPipeline.new
    qs.filter_to_shop.filter_to_active.filter_to_employers_feins(clean_feins).with_effective_date({"$gt" => (@publish_date - 1.day)}).eliminate_family_duplicates
    enroll_pol_ids = []
    excluded_ids = []
    qs.evaluate.each do |r|
      enroll_pol_ids << r['hbx_id']
    end
    puts "----Current Enrollment Count = #{enroll_pol_ids.count}----"
  end
  
end


# renewal_begin_date = Date.new(2019, 1, 1)
# orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => renewal_begin_date, :aasm_state.in => PlanYear::RENEWING}})

# def enrollment_details_by_coverage_kind(enrollments, coverage_kind)
#   enrollment = enrollments.where(:coverage_kind => coverage_kind).sort_by(&:submitted_at).last
#   return [] if enrollment.blank?
#   [
#     enrollment.hbx_id,
#     enrollment.plan.hios_id,
#     enrollment.effective_on.strftime("%m/%d/%Y"),
#     enrollment.coverage_kind,
#     enrollment.aasm_state.humanize
#   ]
# end




ar.each do |fein|
  org= Organization.where(fein: fein).first
  py = org.employer_profile.plan_years.last
    puts "#{py.aasm_state}"
    # py.revert_renewal!
  # end
end

# CSV.open("#{Rails.root}/monthly_renewal_employer_enrollment_detail_report_#{renewal_begin_date.strftime('%m_%d')}.csv", "w") do |csv|
#   csv << [
#     "Employer Legal Name",
#     "Employer FEIN",
#     "Renewal State",
#     "First name",
#     "Last Name",
#     "Roster status",
#     "Hbx ID",
#     "#{renewal_begin_date.prev_year.year} enrollment", 
#     "#{renewal_begin_date.prev_year.year} plan", 
#     "#{renewal_begin_date.prev_year.year} effective_date",
#     "#{renewal_begin_date.prev_year.year} enrollment kind",
#     "#{renewal_begin_date.prev_year.year} status",
#     "#{renewal_begin_date.year} enrollment", 
#     "#{renewal_begin_date.year} plan", 
#     "#{renewal_begin_date.year} effective_date",
#     "#{renewal_begin_date.year} enrollment kind",
#     "#{renewal_begin_date.year} status"
#   ]
#   orgs.each do |organization|

#     puts "Processing #{organization.legal_name}"

#     employer_profile = organization.employer_profile
#     next if employer_profile.active_plan_year.blank?
#     active_bg_ids = employer_profile.active_plan_year.benefit_groups.pluck(:id)
#     families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES}})

#     if employer_profile.renewing_plan_year.present?
#       if employer_profile.renewing_plan_year.renewing_enrolling? || employer_profile.renewing_plan_year.renewing_enrolled?
#         renewal_bg_ids = employer_profile.renewing_plan_year.benefit_groups.pluck(:id)
#       end
#     end

#     puts "found #{families.count} families"
#     families.each do |family|
#       begin
#         enrollments = family.active_household.hbx_enrollments.where({
#           :benefit_group_id.in => active_bg_ids,
#           :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
#         })

#         employee_role = enrollments.last.employee_role 
#         if employee_role.present?
#           employee = employee_role.census_employee
#         end

#         if employee.blank?
#             puts "#{faamily}-----#{family.primary_applicant}" if person.nil? || family.primary_applicant.nil?
#             person = family.primary_applicant.person
            
#             role = person.employee_roles.detect{|role| role.employer_profile_id.to_s == employer_profile.id.to_s} 
#             employee = role.census_employee
#         end

#         if renewal_bg_ids.present?
#           renewal_enrollments = family.active_household.hbx_enrollments.where({
#             :benefit_group_id.in => renewal_bg_ids,
#             :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
#             })
#         end

#         employer_employee_data = [
#           employer_profile.legal_name,
#           employer_profile.fein,
#           employer_profile.renewing_plan_year.aasm_state.camelcase
#         ]

#         if employee.present?
#           employer_employee_data += [employee.first_name, employee.last_name, employee.aasm_state.humanize, employee_role.person.hbx_id] 
#         else
#           employer_employee_data += [nil, nil, nil, nil]
#         end


#         %w(health dental).each do |coverage_kind|
#           next if enrollments.where(:coverage_kind => coverage_kind).blank?

#           data = employer_employee_data
#           data += enrollment_details_by_coverage_kind(enrollments, coverage_kind)
#           if renewal_bg_ids.present?
#             data += enrollment_details_by_coverage_kind(renewal_enrollments, coverage_kind)
#           end

#           csv << data
#         end
#       rescue Exception => e 
#         puts "Failed: #{family.id} #{e.to_s}"
#         next
#       end
#     end
#   end
# end




# date = Date.today

# if date.day > 15
#   window_start = Date.new(date.year,date.month,16)
#   window_end = Date.new(date.next_month.year,date.next_month.month,15)
#   window = (window_start..window_end)
# elsif date.day <= 15
#   window_start = Date.new((date - 1.month).year,(date - 1.month).month,16)
#   window_end = Date.new(date.year,date.month,15)
#   window = (window_start..window_end)
# end

# start_on_date = window.end.next_month.beginning_of_month.to_time.utc.beginning_of_day

# feins = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => start_on_date, :aasm_state => 'renewing_enrolling'}}).pluck(:fein)

# clean_feins = feins.map do |f|
#   f.gsub(/\D/,"")
# end

# qs = Queries::PolicyAggregationPipeline.new
# qs.filter_to_shop.filter_to_active.filter_to_employers_feins(clean_feins).with_effective_date({"$gt" => (start_on_date - 1.day)}).eliminate_family_duplicates
# enroll_pol_ids = []
# excluded_ids = []
# qs.evaluate.each do |r|
#   enroll_pol_ids << r['hbx_id']
# end

# puts enroll_pol_ids.count


# bundle exec rails r script/policies_for_simulated_renewals.rb -e production
# mv policies_to_pull_ies.txt policies_to_pull.txt
# mkdir policy_cvs
# bundle exec rails r script/write_enrollment_files.rb -e production
# mkdir source_xmls
# mv policy_cvs/*.xml source_xmls

# # Get all the renewal enrollment CVs
# mv policies_to_pull.txt policies_to_pull_ies.txt
# mv policies_to_pull_renewals.txt policies_to_pull.txt
# sed -i 's/urn:openhbx:terms:v1:enrollment#initial/urn:openhbx:terms:v1:enrollment#active_renew/' app/views/events/enrollment_event.xml.haml
# bundle exec rails r script/write_enrollment_files.rb -e production
# mv policy_cvs/*.xml source_xmls > /dev/null
# echo "Total XMLs to send to Glue"
# ls source_xmls/*.xml | wc -l
# sed -i 's/urn:openhbx:terms:v1:enrollment#active_renew/urn:openhbx:terms:v1:enrollment#initial/' app/views/events/enrollment_event.xml.haml

# zip -er -P 'dcaspasswd' source_xmls.zip source_xmls







# renewal_begin_date = Date.new(2019,1,1)
# orgs = Organization.where(:"employer_profile.plan_years" => {:$elemMatch => {:start_on => renewal_begin_date, :aasm_state.in => PlanYear::RENEWING}})

# CSV.open("#{Rails.root}/monthly_renewal_employer_enrollment_report_#{renewal_begin_date.strftime('%m_%d')}.csv", "w") do |csv|
#   csv << [
#     "Employer Legal Name",
#     "Employer FEIN",
#     "Renewal State",
#     "#{renewal_begin_date.prev_year.year} Active Enrollments",
#     "#{renewal_begin_date.prev_year.year} Passive Renewal Enrollments"
#   ]

#   orgs.each do |organization|

#     puts "Processing #{organization.legal_name}"

#     employer_profile = organization.employer_profile

#     data = [
#       employer_profile.legal_name,
#       employer_profile.fein,
#       employer_profile.renewing_plan_year.aasm_state.camelcase
#     ]
#     next if employer_profile.active_plan_year.blank?

#     active_bg_ids = employer_profile.active_plan_year.benefit_groups.pluck(:id)
#     families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:benefit_group_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES}})

#     if employer_profile.renewing_plan_year.present?
#       if employer_profile.renewing_plan_year.renewing_enrolling? || employer_profile.renewing_plan_year.renewing_enrolled?
#         renewal_bg_ids = employer_profile.renewing_plan_year.benefit_groups.pluck(:id)
#       end
#     end

#     active_enrollment_count = 0
#     renewal_enrollment_count = 0

#     families.each do |family|

#       enrollments = family.active_household.hbx_enrollments.where({
#         :benefit_group_id.in => active_bg_ids,
#         :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
#       })

#       %w(health dental).each do |coverage_kind|
#         if enrollments.where(:coverage_kind => coverage_kind).present?
#           active_enrollment_count += 1
#         end
#       end

#       if renewal_bg_ids.present?
#         renewal_enrollments = family.active_household.hbx_enrollments.where({
#           :benefit_group_id.in => renewal_bg_ids,
#           :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
#         })

#         %w(health dental).each do |coverage_kind|
#           if renewal_enrollments.where(:coverage_kind => coverage_kind).present?
#             renewal_enrollment_count += 1
#           end
#         end
#       end
#     end

#     data += [active_enrollment_count, renewal_enrollment_count]
#     csv << data
#   end
# end