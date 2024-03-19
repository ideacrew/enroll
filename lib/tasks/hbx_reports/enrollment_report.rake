# frozen_string_literal: true

require 'rake'
# The task to run is RAILS_ENV=production bundle exec rake reports:enrollment_report_generate start_on="1/1/2022" end_on="12/31/2022"
namespace :reports do
  desc 'List of enrollments for the given dates'
  task enrollment_report_generate: :environment do
    start_on = ENV['start_on']
    end_on = ENV['end_on']

    def fpl_percentage(enr, enr_member, effective_year)
      tax_households = if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
                         enr.family.tax_household_groups.active.by_year(effective_year).first&.tax_households
                       else
                         enr.household.latest_tax_households_with_year(effective_year).active_tax_household
                       end
      return "N/A" if tax_households.blank?

      tax_household_member = tax_households.map(&:tax_household_members).flatten.detect{|mem| mem.applicant_id == enr_member.applicant_id}
      tax_household_member&.magi_as_percentage_of_fpl
    end

    def total_responsible_amount(enr)
      (enr.total_premium - enr.applied_aptc_amount.to_f).to_f.round(2)
    end

    def all_enrollments_for_year(enr, all_enrollments, person)
      states = HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES
      all_enrollments.select do |enrollment|
        enrollment_member_hbx_ids = enrollment.hbx_enrollment_members.flat_map(&:person).pluck(:hbx_id)
        states.include?(enrollment.aasm_state) && enrollment.coverage_kind == enr.coverage_kind &&
          enrollment.effective_on >= enr.effective_on.beginning_of_year &&
          enrollment_member_hbx_ids.include?(person.hbx_id)
      end
    end

    def pre_11_1_purchase_enrollments(enr, all_enrollments, person)
      time_period = Time.zone.parse("2022-11-01 10:00:00").utc
      states = HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES
      all_enrollments.select do |enrollment|
        enrollment_member_hbx_ids = enrollment.hbx_enrollment_members.flat_map(&:person).pluck(:hbx_id)
        enrollment.created_at < time_period && states.include?(enrollment.aasm_state) &&
          enrollment.coverage_kind == enr.coverage_kind &&
          enrollment.effective_on >= enr.effective_on.beginning_of_year &&
          enrollment_member_hbx_ids.include?(person.hbx_id)
      end
    end

    def post_11_1_purchase_enrollments(enr, all_enrollments, person)
      time_period = Time.zone.parse("2022-11-01 10:00:00").utc
      states = HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES
      all_enrollments.select do |enrollment|
        enrollment_member_hbx_ids = enrollment.hbx_enrollment_members.flat_map(&:person).pluck(:hbx_id)
        enrollment.created_at >= time_period && states.include?(enrollment.aasm_state) &&
          enrollment.coverage_kind == enr.coverage_kind &&
          enrollment.effective_on >= enr.effective_on.beginning_of_year &&
          enrollment_member_hbx_ids.include?(person.hbx_id)
      end
    end

    def renewed_enrollments(enr, all_enrollments, person)
      states = HbxEnrollment::RENEWAL_STATUSES + HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::TERMINATED_STATUSES
      all_enrollments.select do |enrollment|
        enrollment_member_hbx_ids = enrollment.hbx_enrollment_members.flat_map(&:person).pluck(:hbx_id)
          states.include?(enrollment.aasm_state) &&
          enrollment.coverage_kind == enr.coverage_kind &&
          enrollment.effective_on >= enr.effective_on.beginning_of_year &&
          enrollment_member_hbx_ids.include?(person.hbx_id) &&
          enrollment.workflow_state_transitions.any? do |wst|
            HbxEnrollment::RENEWAL_STATUSES.include?(wst.from_state.to_s) || HbxEnrollment::RENEWAL_STATUSES.include?(wst.to_state.to_s)
          end
      end
    end

    def all_effectuated_enrollments_for_prev_year(enr, all_enrollments, person)
      start_date = enr.effective_on.beginning_of_year.prev_year
      end_date = start_date.end_of_year
      states = ['shopping', 'coverage_canceled']

      all_enrollments.select do |enrollment|
        enrollment_member_hbx_ids = enrollment.hbx_enrollment_members.flat_map(&:person).pluck(:hbx_id)
        !states.include?(enrollment.aasm_state) && enrollment.coverage_kind == enr.coverage_kind &&
          enrollment.effective_on.between?(start_date,end_date) &&
          enrollment_member_hbx_ids.include?(person.hbx_id)
      end
    end

    def all_expired_enrollments_for_prev_year(enr, all_enrollments, person)
      start_date = enr.effective_on.beginning_of_year.prev_year
      end_date  = start_date.end_of_year

      states = ['coverage_expired']

      all_enrollments.select do |enrollment|
        enrollment_member_hbx_ids = enrollment.hbx_enrollment_members.flat_map(&:person).pluck(:hbx_id)
        states.include?(enrollment.aasm_state) && enrollment.coverage_kind == enr.coverage_kind &&
          enrollment.effective_on.between?(start_date,end_date) &&
          enrollment_member_hbx_ids.include?(person.hbx_id)
      end
    end

    def has_effectuated_coverage_in_prev_year_during_oe?(enrollment)
      prev_year = enrollment.effective_on.prev_year.year
      @previous_enrollments.select do |enr|
        effective_date = enr.coverage_terminated? ? enr.terminated_on : Date.new(prev_year, 12, 31)
        effective_date.between?(Date.new(prev_year, 11,1),Date.new(prev_year,12,31))
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def member_status(enr)
      enrs_between_nov_and_dec_set = has_effectuated_coverage_in_prev_year_during_oe?(enr)
      re_enrolled_member_set = @enrollments&.map(&:hbx_id)
      active_renewals_set = (re_enrolled_member_set & @post_11_1_purchases&.map(&:hbx_id)) - @renewed_enrollments&.map(&:hbx_id)
      passive_renewals_set = re_enrolled_member_set - (@post_11_1_purchases&.map(&:hbx_id) - @renewed_enrollments&.map(&:hbx_id))

      if active_renewals_set.present? && enrs_between_nov_and_dec_set.present?
        "Active Re-enrollee"
      elsif passive_renewals_set.present? && enrs_between_nov_and_dec_set.present?
        "Re-enrollee"
      elsif enrs_between_nov_and_dec_set.empty? || @previous_enrollments.blank?
        "New Consumer"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def broker_assisted(enr, person)
      broker_role = person&.user.present? ? (person.broker_role || person.active_broker_staff_roles) : nil
      return "No" if broker_role.present?

      enr.writing_agent_id.present? ? "Yes" : "No"
    end

    def ethnicity_status(ethnicity)
      return "unknown" if ethnicity.blank?

      if ethnicity.include?("Mexican") || ethnicity.include?("Mexican American")
        "hispanic"
      else
        "non-hispanic"
      end
    end

    enrollments = HbxEnrollment.where(
      :aasm_state.nin => ['shopping'],
      :effective_on => { "$gte" => Date.strptime(start_on, "%m/%d/%Y"), "$lt" => Date.strptime(end_on, "%m/%d/%Y")}
    )
    count = 0
    batch_size = 1000
    offset = 0
    @member_status_lookup = {}
    total_count = enrollments.size
    CSV.open("enroll_enrollment_report.csv", 'w') do |csv|
      csv << ["Primary Member ID", "Member ID", "Policy ID", "Policy Last Updated", "Policy Subscriber ID", "Status", "Member Status",
              #"First Name", "Last Name","SSN", "DOB", 
              "Age", "Gender", "Relationship", "Benefit Type", "Tobacco Status",
              "Plan Name", "HIOS ID", "Plan Metal Level", "Carrier Name", "Rating Area",
              "Premium Amount", "Premium Total", "Policy APTC", "Responsible Premium Amt", "FPL",
              "Purchase Date", "Coverage Start", "Coverage End", "SEP Reason", "Term Reason",
              #"Home Address", "Mailing Address","Work Email", "Home Email", "Phone Number",
              "Broker", "Broker NPN",
              "Broker Assignment Date","Race", "Ethnicity", "Citizen Status",
              "Broker Assisted", "Predecessor Enrollment HbxID"]
      while offset <= total_count
        enrollments.offset(offset).limit(batch_size).no_timeout.each do |enr|
          count += 1
          begin
            unless enr.subscriber.nil?
              next if enr.subscriber.person.blank?
              family = enr.family
              primary_person = family.primary_person
              primary_person_hbx_id = primary_person.hbx_id
              product = Caches::MongoidCache.lookup(BenefitMarkets::Products::Product, enr.product_id) do
                enr.product
              end
              enr.hbx_enrollment_members.each do |en|
                per = en.person
                premium_amount = (enr.is_ivl_by_kind? ? enr.premium_for(en) : (enr.decorated_hbx_enrollment.member_enrollments.find { |enrollment| enrollment.member_id == en.id }).product_price).to_f.round(2)
                next if per.blank?

                all_enrollments_for_person = per.families.flat_map(&:hbx_enrollments)
                @enrollments = all_enrollments_for_year(enr, all_enrollments_for_person, per)
                @pre_11_1_purchases = pre_11_1_purchase_enrollments(enr, all_enrollments_for_person, per)
                @post_11_1_purchases = post_11_1_purchase_enrollments(enr, all_enrollments_for_person, per)
                @renewed_enrollments = renewed_enrollments(enr, all_enrollments_for_person, per)
                @previous_enrollments = all_effectuated_enrollments_for_prev_year(enr, all_enrollments_for_person, per)
                @all_expired_enrollments = all_expired_enrollments_for_prev_year(enr, all_enrollments_for_person, per)
                csv << [
                  primary_person_hbx_id, per.hbx_id, enr.hbx_id, enr&.updated_at&.to_s,
                  enr.subscriber.hbx_id, enr.aasm_state,
                  @member_status_lookup["#{enr.coverage_kind}_#{per.hbx_id}"] ||= member_status(enr),
                  #per.first_name,
                  #per.last_name,
                  #per.ssn,
                  #per.dob.strftime("%Y%m%d"),
                  per.age_on(enr.effective_on),
                  per.gender,
                  en.primary_relationship,
                  enr.coverage_kind,
                  en.tobacco_use_value_for_edi,
                  product.name, product.hios_id, product.metal_level, product.carrier_profile.abbrev,
                  enr&.rating_area&.exchange_provided_code,
                  premium_amount, enr.total_premium, enr.applied_aptc_amount, total_responsible_amount(enr),
                  fpl_percentage(enr, en, enr.effective_on.year),
                  enr&.time_of_purchase&.to_s,
                  enr.effective_on.blank? ? nil : enr.effective_on.strftime("%Y%m%d"),
                  enr.terminated_on.blank? ? nil : enr.terminated_on.strftime("%Y%m%d"),
                  enr.special_enrollment_period&.qualifying_life_event_kind&.reason,
                  enr.terminate_reason,
                  #per.home_address&.full_address || enr.subscriber.person.home_address&.full_address,
                  #per.mailing_address&.full_address || enr.subscriber.person.mailing_address&.full_address,
                  #per.work_email&.address || enr.subscriber.person.work_email&.address,
                  #per.home_email&.address || enr.subscriber.person.home_email&.address,
                  #per.work_phone_or_best || enr.subscriber.person&.work_phone_or_best,
                  family.active_broker_agency_account&.writing_agent&.person&.full_name,
                  family.active_broker_agency_account&.writing_agent&.npn,
                  family.active_broker_agency_account&.start_on&.to_s,
                  per.ethnicity,
                  ethnicity_status(per.ethnicity),
                  per.citizen_status,
                  broker_assisted(enr, primary_person),
                  enr.predecessor_enrollment_hbx_id
                ]
              end
            end
          rescue StandardError => e
            puts "Unable to process enrollment #{enr.hbx_id} due to error #{e}"
          end
        end
        offset += batch_size
        puts "#{count}/#{total_count} done at #{Time.now}" if count % 10_000 == 0
        puts "#{count}/#{total_count} done at #{Time.now}" if count == total_count
      end
      puts "End of the report" unless Rails.env.test?
    end
  end
end
