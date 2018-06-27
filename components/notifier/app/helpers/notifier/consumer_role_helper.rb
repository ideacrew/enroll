module Notifier
  module ConsumerRoleHelper

    def build_enrollments
      hbx_enrollments = check_for_consumer_enrollments(consumer_role)
      hbx_enrollments.collect do |enr|
        enrollment = Notifier::MergeDataModels::Enrollment.new
        enrollment.plan_name = enr.plan.name
        enrollment.phone = phone_number(enr.plan.carrier_profile.legal_name)
        enrollment.premium_amount = enr.total_premium.to_f.round(2)
        enrollment.aptc_amount =  enr.applied_aptc_amount.to_f.round(2)
        enrollment.plan_carrier = enr.plan.carrier_profile.organization.legal_name
        enrollment.responsible_amount = (enr.total_premium.to_f - enr.applied_aptc_amount.to_f).round(2)
        enrollment.deductible =  enr.plan.deductible
        enrollment.coverage_kind = enr.coverage_kind
        enrollment.coverage_start_on = enr.effective_on.strftime('%m/%d/%Y')
        enrollment.created_at = enr.created_at.strftime("%B %d, %Y")
        enrollment.health_plan = enr.coverage_kind == "health"
        enrollment.family_deductible =  enr.plan.family_deductible.split("|").last.squish
        consumer = enr.subscriber.person
        enrollment.subscriber = MergeDataModels::Person.new(first_name: consumer.first_name, last_name: consumer.last_name, age: consumer.age_on(TimeKeeper.date_of_record))

        enrollees = enr.hbx_enrollment_members.map(&:person)
        enrollees.each do |enrolle|
          enrolle = MergeDataModels::Person.new(first_name: enrolle.first_name, last_name: enrolle.last_name, age: enrolle.age_on(TimeKeeper.date_of_record))
          enrollment.enrollees << enrolle
        end
        enrollment.enrolles_count = enrollment.enrollees.count
        enrollment
      end
    end

    def check_for_consumer_enrollments(consumer_role)
      family = consumer_role.person.primary_family
      date = TimeKeeper.date_of_record
      start_time = (date).in_time_zone("Eastern Time (US & Canada)").beginning_of_day
      end_time = (date).in_time_zone("Eastern Time (US & Canada)").end_of_day
      enrollments = family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
        (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
            (hbx_en.terminated_on.blank? || hbx_en.terminated_on >= TimeKeeper.date_of_record) &&
            (hbx_en.created_at >= start_time && hbx_en.created_at <= end_time)
      end
      enrollments.reject!{|e| e.coverage_terminated? }

      hbx_enrollments = []
      en = enrollments.select{ |en| HbxEnrollment::ENROLLED_STATUSES.include?(en.aasm_state)}
      health_enrollments = en.select{ |e| e.coverage_kind == "health"}.sort_by(&:effective_on)
      dental_enrollments = en.select{ |e| e.coverage_kind == "dental"}.sort_by(&:effective_on)
      hbx_enrollments << health_enrollments
      hbx_enrollments << dental_enrollments
      hbx_enrollments.flatten!
      hbx_enrollments.compact!
      hbx_enrollments
    end

    def outstanding_people(consumer_role)
      enrollments =check_for_consumer_enrollments(consumer_role)
      family_members = enrollments.inject([]) do |family_members, enrollment|
        family_members += enrollment.hbx_enrollment_members.map(&:family_member)
      end.uniq
      people = family_members.map(&:person).uniq
      outstanding_people = []
      people.each do |person|
        if person.consumer_role.outstanding_verification_types.present?
          outstanding_people << person
        end
      end
      outstanding_people
    end

    def update_due_date(consumer_role)
      family = consumer_role.person.primary_family
      people = outstanding_people(consumer_role)
      date = TimeKeeper.date_of_record
      people.each do |person|
        person.consumer_role.outstanding_verification_types.each do |verification_type|
          unless person.consumer_role.special_verifications.where(:"verification_type" => verification_type).present?
            special_verification = SpecialVerification.new(due_date: (date + Settings.aca.individual_market.verification_due.days), verification_type: verification_type, type: "notice")
            person.consumer_role.special_verifications << special_verification
            person.consumer_role.save!
          end
        end
      end
      family.update_attributes(min_verification_due_date: family.min_verification_due_date_on_family) unless family.min_verification_due_date.present?
      family.min_verification_due_date
    end

    def notice_coverage_year(consumer_role)
      enrollments = check_for_consumer_enrollments(consumer_role)
      latest_hbx_enrollment = enrollments.sort_by(&:effective_on).last
      latest_hbx_enrollment.effective_on.year
    end

    def enr_line
      if uqhp_present? && aqhp_present?
        if uqhp_and_dental_present?
          subject = "Your Health Plan, Cost Savings, and Dental Plan"
        else
          subject = "Your Health Plan and Cost Savings"
        end
      elsif  uqhp_present? && !aqhp_present?
        if uqhp_and_dental_present?
          subject = "Your Health and Dental Plan"
        else
          subject = "Your Health Plan"
        end
      else
        subject = "Your Dental Plan"
      end
    end

    def phone_number(legal_name)
      case legal_name
      when "BestLife"
        "(800) 433-0088"
      when "CareFirst"
        "(855) 444-3119"
      when "Delta Dental"
        "(800) 471-0236"
      when "Dominion"
        "(855) 224-3016"
      when "Kaiser"
        "(844) 524-7370"
      end
    end


  end
end
