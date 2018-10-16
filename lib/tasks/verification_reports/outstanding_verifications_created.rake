require 'csv'

# Both reports outlined in 21119 and 21123 will utilize the same rake task.
# For 21123 we will have an additional switch to remove Duplicates.

# 21119 - Include Duplicates (Report Filename: all_outstanding_types_created_[Month]_[Year].csv)
# # RAILS_ENV=production bundle exec rake reports:outstanding_types_created date=Month,Year (example: January,2018)

# 21123 - Remove Duplicates (Report Filename: current_outstanding_types_created_[Month]_[Year].csv)
# # RAILS_ENV=production bundle exec rake reports:outstanding_types_created date=Month,Year remove_dup=true

namespace :reports do
  desc "Outstanding verifications created monthly report"
  task :outstanding_types_created => :environment do
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME VERIFICATION_TYPE TRANSITION OUTSTANDING DUE_DATE IVL_ENROLLMENT SHOP_ENROLLMENT)

    CITIZEN_INVALID_EVENTS = ["ssn_valid_citizenship_invalid!", "ssn_valid_citizenship_invalid", "fail_dhs!", "fail_dhs"]

    SSN_INVALID_EVENTS = ["ssn_valid_citizenship_invalid!", "ssn_valid_citizenship_invalid", "ssn_invalid!", "ssn_invalid"]

    RESIDENCY_INVALID_EVENTS = ["fail_residency!", "fail_residency"]

    IMMIGRATION_INVALID_EVENTS = ["fail_dhs!", "fail_dhs"]

    ALL_EVENTS = ["ssn_valid_citizenship_invalid!", "ssn_valid_citizenship_invalid", "fail_dhs!", "fail_dhs", "fail_residency!", "fail_residency"]

    def date
      begin
        ENV["date"].strip
      rescue
        puts 'Provide report month.'
      end
    end

    def ivl_enrollment(person)
      if person.primary_family
        if person.primary_family.active_household.hbx_enrollments.individual_market.present?
          person.primary_family.active_household.hbx_enrollments.individual_market.select{|enrollment| enrollment.currently_active? }.any? ? "YES" : "NO"
        else
          "nil"
        end
      else
        families = person.families.select{|family| family.active_household.hbx_enrollments.individual_market.present?}
        enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| !(["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
        all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
        active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state)}
        return "nil" unless all_enrollments.any?
        active_enrollments.any? ? "YES" : "NO"
      end
    end

    def shop_enrollment(person)
      if person.primary_family
        if person.primary_family.active_household.hbx_enrollments.shop_market.present?
          person.primary_family.active_household.hbx_enrollments.shop_market.select{|enrollment| enrollment.currently_active? }.any? ? "YES" : "NO"
        else
          "nil"
        end
      else
        families = person.families.select{|family| family.active_household.hbx_enrollments.shop_market.present?}
        enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| (["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
        all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
        active_enrollments = enrollments.select{|enrollment| enrollment.currently_active?}
        return "nil" unless all_enrollments.any?
        active_enrollments.any? ? "YES" : "NO"
      end
    end

    def subscriber_id(person)
      if person.primary_family
        person.hbx_id
      else
        primary = person.families.map(&:primary_family_member).select{|member| member.person.consumer_role.present?}.first || person.families.map(&:primary_family_member).first
        primary ? primary.hbx_id : person.hbx_id
      end
    end

    def start_date
      Date.parse(date)
    end

    def end_date
      Date.parse(date).next_month
    end

    def type_history_elements_with_date_range(v_type)
     history_elements =  v_type.type_history_elements.
      where(created_at:{
        :"$gte" => start_date,
        :"$lt" => end_date},
        :"$or" => [
          {:"action" => "return for deficiency"},
          {:"modifier" => "external Hub"}
        ]
      )
      remove_dup_override? ? [history_elements.sort_by{|type_history| type_history.updated_at}.last] : history_elements
    end

    def remove_dup_override?
      ENV["remove_dup"].present? && ENV["remove_dup"] == "true"
    end

    def people
      Person.where(:"verification_types.type_history_elements" => { :"$elemMatch" => {
        :"created_at" => {
          :"$gte" => start_date,
          :"$lt" => end_date
        },
        :"$or" => [
          {:"action" => "return for deficiency"},
          {:"modifier" => "external Hub"}
        ]
      }})
    end

    def hub_response_wfst(verification_type)
      hub_response_on = @history_element.created_at.to_date
      v_type = verification_type.type_name
      @person.consumer_role.workflow_state_transitions.where(:"created_at" => {
        :"$gt" => hub_response_on - 1.day,
        :"$lt" => hub_response_on + 1.day
        },
        :"event".in => (verification_valid_event(v_type))
      ).first
    end

    def verification_valid_event(v_type)
      case v_type
        when 'Social Security Number'
          SSN_INVALID_EVENTS
        when 'DC Residency'
          RESIDENCY_INVALID_EVENTS
        when 'Immigration status'
          IMMIGRATION_INVALID_EVENTS
        when 'Citizenship'
          CITIZEN_INVALID_EVENTS
        else
          ALL_EVENTS
      end
    end

    def due_date_for_type(type)
      type.due_date ||  TimeKeeper.date_of_record + 95.days
    end
    def is_not_eligible_transaction?(v_type)
      return false if @history_element.modifier != "external Hub"
      hub_response_wfst(v_type).blank?
    end

    report_prefix = remove_dup_override? ? "current" : "all"
    file_name = "#{Rails.root}/#{report_prefix}_outstanding_types_created_#{date.gsub(" ", "").split(",").join("_")}.csv"

    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      collect_rows = []
      people.each do |person|
        begin
          @person = person
          person.verification_types.each do |v_type|
            type_history_elements_with_date_range(v_type).each do |type_history|
            @history_element = type_history
            next if is_not_eligible_transaction?(v_type)
            collect_rows << [
                    subscriber_id(person),
                    person.hbx_id,
                    person.first_name,
                    person.last_name,
                    v_type.type_name,
                    type_history.updated_at,
                    "outstanding",
                    due_date_for_type(v_type).to_date,
                    ivl_enrollment(person),
                    shop_enrollment(person)
                ]
            end
         end
         rescue => e
         puts "Invalid Person with HBX_ID: #{person.hbx_id}"
        end
      end

      collect_rows.each do |row|
        csv << row
      end
      puts "*********** DONE ******************"
    end
  end
end