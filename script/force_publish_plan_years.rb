class ForcePublishPlanYears
  
  def initialize(publish_date, current_date)  
    @publish_date = publish_date
    @current_date = current_date
  end
  
  def call 
    revert_plan_years #revert plan years that are in renewing_published to renewing_draft and set back their OE start dates    
    assign_packages #assign benefit packages to census employeess missing them    
    set_back_oe_date #set back oe dates for renewing draft employers with oe dates greater than current date 
    force_publish #first run at force publish
    clean_up #take any employers that moved to renewing_published, revert their plan years to renewing_draft and set back their OE start dates
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
    plan_years_in_aasm_state(['renewing_published']).each do |org|
      py = org.employer_profile.plan_years.where(aasm_state: 'renewing_published').first
      if py.may_revert_renewal?
        py.revert_renewal!
        py.update_attributes!(open_enrollment_start_on: @current_date)
      end
    end
  end
  
  def assign_packages
    CSV.open("#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv", "w") do |csv|
      csv << ["Org", "Employee"]
      plan_years_in_aasm_state(['renewing_draft']).each do |org|
        py = org.employer_profile.renewing_plan_year
        if py.application_errors.present?
          save_ce(org, py, csv)
        end
      end
    end 
  end

  def save_ce(org, py, csv)
    org.employer_profile.census_employees.each do |ce|
      if ce.benefit_group_assignments.where(:benefit_group_id.in => py.benefit_groups.map(&:id)).blank?
        data = [org.fein, ce.full_name]  
        csv << data 
        ce.try(:save!)
      end
    end
  end

  def force_publish
    plan_years_in_aasm_state(['renewing_draft']).each do |org|
      py = org.employer_profile.renewing_plan_year
      org.employer_profile.renewing_plan_year.force_publish! if py.may_force_publish? && py.is_application_valid?
    end
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
  
  def set_back_oe_date
    plan_years_in_aasm_state(['renewing_draft']).each do |org|
      py = org.employer_profile.plan_years.last
      if py.open_enrollment_start_on > @current_date
        py.update_attributes!(open_enrollment_start_on: @current_date)
        py.save!
      end
    end
  end
end


# Organization.where({
#   :'employer_profile.plan_years' =>
#   { :$elemMatch => {
#     :start_on => @publish_date
#     }}
#     }).each do |org|
     
#         puts org.employer_profile.plan_years.last.open_enrollment_start_on
#         puts org.employer_profile.plan_years.last.aasm_state
  
# end



# Organization.where({
#   :'employer_profile.plan_years' =>
#     { :$elemMatch => {
#       :start_on => @publish_date,
#       :$or => [
#         {:aasm_state => 'renewing_draft'}, 
#         {:aasm_state => 'renewing_publish_pending'}, 
#         {:aasm_state => 'renewing_enrolled'}, 
#         {:aasm_state => 'renewing_published'}
#       ]
#     }}
#   })
# publish = ForcePublishPlanYears.new(Date.new(2018,12,1), Date.new(2018,10,10))
# publish.call



  # Organization.where({
  #   :'employer_profile.plan_years' =>
  #   { :$elemMatch => {
  #     :aasm_state => 'renewing_draft'
  #     }}
  #     }).each do |org|
  #       data = []
  #       py = org.employer_profile.renewing_plan_year
  #       if py.application_errors.present?
  #         org.employer_profile.census_employees.each do |ce|
  #           if unassigned(ce)
  #             puts ce.id
  #           end
  #         end
  #       end
  #   end

  #           :$or => [
    # {:aasm_state => 'renewing_draft'}, 
    # {:aasm_state => 'renewing_publish_pending'}, 
    # {:aasm_state => 'renewing_enrolled'}, 
    # {:aasm_state => 'renewing_published'}

