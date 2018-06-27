module Notifier
  class Builders::ConsumerRole
    include ActionView::Helpers::NumberHelper
    include Notifier::Builders::Enrollment
    include ConsumerRoleHelper

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

    def outstanding_people
      merge_model.outstanding_people = append_unverified_individuals
    end

    def current_health_enrollments
      merge_model.current_health_enrollments = merge_model.enrollments.select{|enr| enr.coverage_kind == 'health' && enr.aptc_amount.to_f > 0}
    end

    def enr_subject_line
      merge_model.enr_subject_line  = enr_line
    end

    def coverage_year
      merge_model.coverage_year = notice_coverage_year(consumer_role).to_s
    end

    def documents_due_date
        due_date = update_due_date(consumer_role)
        merge_model.documents_due_date = due_date
    end

    def appeal_deadline
      merge_model.appeal_deadline = (TimeKeeper.date_of_record + 95.days).strftime('%m/%d/%Y')
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

    def uqhp_present?
      consumer_role.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "health" && enrollment.effective_on.year.to_s == merge_model.coverage_year && !(enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr? ? true: false)}.present?
    end

    def aqhp_present?
      consumer_role.person.primary_family.enrollments.select{|enrollment| (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr? ? true: false)  && enrollment.effective_on.year.to_s == merge_model.coverage_year}.present?
    end

    def csr_enrollment_present?
      consumer_role.person.primary_family.enrollments.select{|enrollment|  enrollment.effective_on.year.to_s == merge_model.coverage_year && enrollment.plan.is_csr? ==  true}.present?
    end
    def uqhp_and_dental_present?
      uqhp_present? || consumer_role.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "dental" && enrollment.effective_on.year.to_s == merge_model.coverage_year && !(enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr? ? true: false) }.present?
    end

    def aqhp_and_dental_present?
      aqhp_present? &&  consumer_role.person.primary_family.enrollments.select{|enrollment| enrollment.coverage_kind == "dental" && enrollment.effective_on.year.to_s == merge_model.coverage_year}.present?
    end

    def aqhp_or_uqhp_present?
      uqhp_present? || aqhp_present?
    end

    def documents_needed?
      family = consumer_role.person.primary_family
      outstanding_people =  outstanding_people(consumer_role)
      family.has_valid_e_case_id? ? false : (outstanding_people.present? ? true : false)
    end

  end
end
