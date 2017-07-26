FEINS= ['943148303', '464579728', '043839260', '900673864', '521689957', '461792659', '521503793', '520971454', '911930832', '311767734', '331003480', '522074374', '522069263', '530198102']

FEINS.each do |fein|
  organizations = Organization.where(fein: fein)

  if organizations.size != 1
    puts "something went wrong with employer: #{fein}"
  else
    organization = organizations.first
    plan_year = organization.employer_profile.plan_years.detect { |py| py.start_on.year == 2017}
  
    if plan_year.present?
      bg_list = plan_year.benefit_groups.map(&:id)
      Family.where(:"households.hbx_enrollments.benefit_group_id".in => bg_list).each do |family|
        enrollments = family.active_household.hbx_enrollments.where(:benefit_group_id.in => bg_list).to_a
        if enrollments.present?
          puts "caneled 2017 enrollments for family of #{family.primary_applicant.person.full_name} with ER: #{organization.legal_name}"
        end

        enrollments.each do |enrollment|
          enrollment.cancel_coverage! if enrollment.may_cancel_coverage?
        end
      end
      # cannot use state machine events, b'coz plan year is in active status
      plan_year.update_attributes(aasm_state: 'renewing_canceled')
      puts "moved 2017 plan year state to renewing canceled"
    end

    plan_year = organization.employer_profile.plan_years.detect { |py| py.start_on.year == 2016 && py.is_conversion }

    if plan_year.present?
      if plan_year.may_conversion_expire?
        plan_year.conversion_expire!
        puts 'moved 2016 plan year state to conversion expired'
      end
    end
    organization.employer_profile.revert_application! if organization.employer_profile.may_revert_application?
  end
end

HbxEnrollment.by_hbx_id('412161').first.update_attributes(terminated_on: Date.new(2016,12,31))

Organization.where(legal_name: /Early Autism Solutions/i).first.employer_profile.plan_years.where(start_on: Date.new(2016,1,1)).first.update_attributes(:terminated_on => Date.new(2016,12,31), aasm_state: 'terminated')

CensusEmployee.where(first_name: "Sofia", middle_name: "", last_name: "Caldwell").first.update_attributes(employment_terminated_on: Date.new(2016,12,31), coverage_terminated_on: Date.new(2016,12,31))

CensusEmployee.where(first_name: "Sofia", middle_name: "", last_name: "Caldwell").first.terminate_employee_role!
