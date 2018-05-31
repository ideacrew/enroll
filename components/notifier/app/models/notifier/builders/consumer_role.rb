module Notifier
  class Builders::ConsumerRole
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::Enrollment

    attr_accessor :consumer_role, :merge_model, :payload

    def initialize
      data_object = Notifier::MergeDataModels::ConsumerRole.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      data_object.enrollments = [Notifier::MergeDataModels::Enrollment.new]
      @merge_model = data_object
    end

    def resource=(resource)
      @consumer_role = resource
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def first_name
      merge_model.first_name = consumer_role.person.first_name if consumer_role.present?
    end

    def last_name
      merge_model.last_name = consumer_role.person.last_name if consumer_role.present?
    end

    def enrollments
      merge_model.enrollments = build_enrollments
    end

    def current_health_enrollments
      merge_model.current_health_enrollments = merge_model.enrollments.select{|enr| enr.coverage_kind == 'health'}
    end

    def build_enrollments
      family = consumer_role.person.primary_family
      date = TimeKeeper.date_of_record
      start_time = (date - 7.days).in_time_zone("Eastern Time (US & Canada)").beginning_of_day
      end_time = (date - 7.days).in_time_zone("Eastern Time (US & Canada)").end_of_day
      enrollments = family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
        (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
            (hbx_en.terminated_on.blank? || hbx_en.terminated_on >= TimeKeeper.date_of_record) &&
            (hbx_en.created_at >= start_time && hbx_en.created_at <= end_time)
      end
      enrollments
      enrollments.collect do |enr|
        enrollment = Notifier::MergeDataModels::Enrollment.new

        enrollment.plan_name = enr.plan.name
        enrollment.premium_amount = enr.total_premium
        enrollment.plan_carrier = enr.plan.carrier_profile.organization.legal_name
        enrollment.responsible_amount = (enr.total_premium - enr.applied_aptc_amount.to_f).round(2)
        enrollment.family_deductible = enr.plan.family_deductible.split("|").last.squish
        enrollment.deductible =  enr.plan.deductible
        enrollment.coverage_kind = enr.coverage_kind
        enrollment.coverage_start_on = enr.effective_on.strftime('%m/%d/%Y')
        enrollment.created_at = enr.created_at
        enrollment.aasm_state = enr.aasm_state
        consumer = enr.subscriber.person
        enrollment.subscriber = MergeDataModels::Person.new(first_name: consumer.first_name, last_name: consumer.last_name)

        enrollees = enr.hbx_enrollment_members.map(&:person)
        enrollees.each do |enrolle|
          enrolle = MergeDataModels::Person.new(first_name: enrolle.first_name, last_name: enrolle.last_name)
          enrollment.enrollees << enrolle
        end
        # enrolles = enr.hbx_enrollment_members.inject([]) do |enrollees, member|
        #   enrollee << MergeDataModels::Person.new(first_name: member.person.first_name, last_name: member.person.last_name, age: member.person.age_on(TimeKeeper.date_of_record))
        #   enrolles << enrollee
        # end
        enrollment
      end
    end

    def append_contact_details
      mailing_address = consumer_role.person.mailing_address
      if mailing_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
                                                                       street_1: mailing_address.address_1,
                                                                       street_2: mailing_address.address_2,
                                                                       city: mailing_address.city,
                                                                       state: mailing_address.state,
                                                                       zip: mailing_address.zip
                                                                   })
      end
    end







    def line
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

    def subject_line
      merge_model.subject_line  = self.line.upcase
    end

    def uqhp_present?
     consumer_role.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "health" && enrollment.effective_on.year.to_s == "2018" && !(enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr? ? true: false)}.present?
    end

    def aqhp_present?
      consumer_role.person.primary_family.enrollments.select{|enrollment| (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr? ? true: false)  && enrollment.effective_on.year.to_s == "2018"}.present?
    end

    def uqhp_and_dental_present?
      consumer_role.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "dental" && enrollment.effective_on.year.to_s == "2018" && !(enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr? ? true: false) }.present?
    end

    def aqhp_and_dental_present?
      aqhp_present? &&  consumer_role.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "dental" && enrollment.effective_on.year.to_s == "2018"}.present?
    end

    def documents_needed?
      family = consumer_role.person.primary_family
      date = TimeKeeper.date_of_record
      start_time = (date - 2.days).in_time_zone("Eastern Time (US & Canada)").beginning_of_day
      end_time = (date - 2.days).in_time_zone("Eastern Time (US & Canada)").end_of_day
      enrollments = family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
        (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
            (hbx_en.terminated_on.blank? || hbx_en.terminated_on >= TimeKeeper.date_of_record) &&
            (hbx_en.created_at >= start_time && hbx_en.created_at <= end_time)
      end
      enrollments.reject!{|e| e.coverage_terminated? }
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
     family.has_valid_e_case_id? ? false : (outstanding_people.present? ? true : false)
    end

  end
end
