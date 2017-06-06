qs = Queries::PolicyAggregationPipeline.new

qs.filter_to_active_terminated_expired.with_effective_date({"$gt" => Date.new(2015,12,31)}).eliminate_family_duplicates

enroll_pol_ids = []

qs.evaluate.each do |r|
    enroll_pol_ids << r['hbx_id']
end

glue_list = File.read("all_glue_policies.txt").split("\n").map(&:strip)

missing = (enroll_pol_ids - glue_list)

timestamp = Time.now.strftime('%Y%m%d%H%M')

puts "#{Time.now} - 0/#{missing.size}"

count = 0

Caches::MongoidCache.with_cache_for(Plan) do
  CSV.open("enrollments_in_enroll_but_not_in_glue_#{timestamp}.csv","w") do |csv|
    csv << ["Subscriber HBX ID", "Enrollee HBX ID", "Enrollment HBX ID", "First Name","Last Name","SSN","DOB","Gender","Relationship to Subscriber",
            "Plan Name", "Plan HIOS ID", "Plan Metal Level", "Carrier Name",
            "Premium for Enrollee", "Premium Total for Policy","APTC/Employer Contribution",
            "Enrollee Coverage Start","Enrollee Coverage End",
            "Employer Name","Employer DBA","Employer FEIN","Employer HBX ID",
            "Home Address","Mailing Address","Home Email", "Work Email","Home Phone Number", "Work Phone Number", "Mobile Phone Number",
            "Broker Name", "Broker NPN",
            "AASM State"]
    missing.each do |eg_id|
      count += 1
      puts "#{Time.now} - #{count}/#{missing.size}" if count % 1000 == 0
      puts "#{Time.now} - #{count}/#{missing.size}" if count == missing.size
      hbx_enrollment = HbxEnrollment.by_hbx_id(eg_id).first
      next if hbx_enrollment.blank?
      plan = Caches::MongoidCache.lookup(Plan, hbx_enrollment.plan_id) { hbx_enrollment.plan }
      plan_name = plan.name
      plan_hios = plan.hios_id
      plan_metal_level = plan.metal_level
      carrier_name = plan.carrier_profile.legal_name
      premium_total = hbx_enrollment.total_premium rescue ""
      if hbx_enrollment.is_shop?
        external_contribution = hbx_enrollment.total_employer_contribution.to_s rescue ""
        employer = hbx_enrollment.employer_profile
        employer_name = employer.legal_name
        employer_dba = employer.dba
        employer_fein = employer.fein
        employer_hbx_id = employer.hbx_id
      else
        external_contribution = hbx_enrollment.applied_aptc_amount.to_s
      end
      if hbx_enrollment.broker_agency_account
        broker_name = hbx_enrollment.broker_agency_account.writing_agent.person.full_name rescue ""
        broker_npn = hbx_enrollment.broker_agency_account.writing_agent.npn rescue ""
      end
      policy_state = hbx_enrollment.aasm_state
      subscriber_hbx_id = hbx_enrollment.subscriber.hbx_id rescue ""
      hbx_enrollment.hbx_enrollment_members.each do |hbx_em|
        person = hbx_em.person rescue ""
        next if person.blank?
        hbx_id = hbx_em.hbx_id
        first_name = person.first_name
        last_name = person.last_name
        ssn = person.ssn
        dob = person.dob
        gender = person.gender
        relationship = hbx_em.primary_relationship
        enrollee_premium = (hbx_enrollment.premium_for(hbx_em).round(2)) rescue ""
        coverage_start = hbx_em.coverage_start_on
        coverage_end = hbx_em.coverage_end_on
        home_address = person.home_address.try(:full_address)
        mailing_address = person.mailing_address.try(:full_address)
        home_email = person.home_email.try(:address)
        work_email = person.work_email.try(:address)
        home_phone = person.home_phone.try(:full_phone_number)
        work_phone = person.work_phone.try(:full_phone_number)
        mobile_phone = person.mobile_phone.try(:full_phone_number)
        csv << [subscriber_hbx_id, hbx_id, eg_id, first_name, last_name, ssn, dob, gender, relationship, plan_name, plan_hios, plan_metal_level, carrier_name,
                enrollee_premium, premium_total, external_contribution, coverage_start, coverage_end, employer_name, employer_dba, employer_fein, employer_hbx_id,
                home_address, mailing_address, home_email, work_email, home_phone, work_phone, mobile_phone, broker_name, broker_npn, policy_state]
      end
    end
  end
end