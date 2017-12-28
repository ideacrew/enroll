batch_size = 500
offset = 0
family_count = Family.count

plan_ids = Plan.where(:active_year => 2018, :market => "individual").map(&:_id)

csv = CSV.open("final_eligibility_notice_#{TimeKeeper.date_of_record.strftime('%m_%d_%Y')}.csv", "w")
csv << %w(ic_number policy.id policy.subscriber.coverage_start_on policy.aasm_state policy.plan.coverage_kind policy.plan.metal_level policy.plan.plan_name policy.total_premium deductible family_deductible  subscriber_id member_id person.first_name person.last_name
        policy.subscriber.person.is_incarcerated  policy.subscriber.person.citizen_status outstanding_verification_types document_due_date
        policy.subscriber.person.is_dc_resident? dependent)


def add_to_csv(csv, policy, person, is_dependent, outstanding_verification_types, document_due_date)
  csv << [policy.family.id, policy.hbx_id, policy.effective_on, policy.aasm_state, policy.plan.coverage_kind, policy.plan.metal_level, policy.plan.name, policy.total_premium, policy.plan.deductible, policy.plan.family_deductible.split("|").last.squish, person.hbx_id, person.hbx_id, person.first_name, person.last_name,
          person.is_incarcerated, person.citizen_status, outstanding_verification_types, document_due_date, 
          is_dc_resident(person)] + [is_dependent]
end

def is_dc_resident(person)
  return false if person.no_dc_address == true && person.no_dc_address_reason.blank?
  return true if person.no_dc_address == true && person.no_dc_address_reason.present?

  address_to_use = person.addresses.collect(&:kind).include?('home') ? 'home' : 'mailing'
  if person.addresses.present?
    if person.addresses.select{|address| address.kind == address_to_use && address.state == 'DC'}.present?
      return true
    else
      return false
    end
  else
    return ""
  end
end

def document_due_date(family)
  enrolled_contingent_enrollment = family.enrollments.where(:aasm_state => "enrolled_contingent", :kind => 'individual').first
  if enrolled_contingent_enrollment.present?
    if enrolled_contingent_enrollment.special_verification_period.present?
      enrolled_contingent_enrollment.special_verification_period.strftime("%m/%d/%Y")
    else
      (TimeKeeper.date_of_record+95.days).strftime("%m/%d/%Y")
    end
  else
    nil
  end
end

def is_family_renewing(family)
  family.active_household.hbx_enrollments.where(:aasm_state.in => ["coverage_selected", "enrolled_contingent"], kind: "individual", effective_on: Date.new(2017,1,1)).present?
end

def check_for_outstanding_verification_types(person)
  outstanding_verification_types = []

  if person.consumer_role.outstanding_verification_types.present?
    outstanding_verification_types << person.consumer_role.outstanding_verification_types
  else
    return nil
  end

  outstanding_verification_types
end

def has_current_aptc_hbx_enrollment(family)
  enrollments = family.latest_household.hbx_enrollments rescue []
  enrollments.any? {|enrollment| (enrollment.effective_on.year == TimeKeeper.date_of_record.next_year.year) && enrollment.applied_aptc_amount > 0}
end

while offset <= family_count
  Family.offset(offset).limit(batch_size).flat_map(&:households).flat_map(&:hbx_enrollments).each do |policy|
    begin
      next if !is_family_renewing(policy.family)
      next if policy.plan.nil?
      next if !plan_ids.include?(policy.plan_id)
      next if policy.effective_on < Date.new(2018, 01, 01)
      next if !(["auto_renewing", "coverage_selected", "enrolled_contingent"].include?(policy.aasm_state))
      next if !(['01', '03', ''].include?(policy.plan.csr_variant_id))#includes dental plans - csr_variant_id - ''
      next if policy.plan.market != 'individual'
      next if (!(['unassisted_qhp', 'individual'].include? policy.kind)) || has_current_aptc_hbx_enrollment(policy.family)

      person = policy.subscriber.person

      add_to_csv(csv, policy, person, "No", check_for_outstanding_verification_types(person), document_due_date(policy.family))

      policy.hbx_enrollment_members.each do |hbx_enrollment_member|
        add_to_csv(csv, policy, hbx_enrollment_member.person, "Yes", check_for_outstanding_verification_types(hbx_enrollment_member.person), document_due_date(policy.family)) if hbx_enrollment_member.person != person
      end
    rescue => e
      puts "Error policy id #{policy.id} family id #{policy.family.id}" + e.message + "   " + e.backtrace.first
    end
  end

  offset = offset + batch_size
end