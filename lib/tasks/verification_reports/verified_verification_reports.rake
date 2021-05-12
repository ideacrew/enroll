require 'csv'
# RAILS_ENV=production bundle exec rake reports:verified_verification_report date="Month,year"  (example: "January, 2018")
namespace :reports do
  desc "Verified verifications created monthly report"
  task :verified_verification_report => :environment do
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME CURRENT_STATUS VERIFICATION_TYPE VERIFIED_DATE VERIFICATION_REASON IVL_ENROLLMENT SHOP_ENROLLMENT)

    CITIZEN_VALID_EVENTS = %w(ssn_valid_citizenship_valid! ssn_valid_citizenship_valid pass_dhs!  pass_dhs)

    SSN_VALID_EVENTS = %w(ssn_valid_citizenship_valid! ssn_valid_citizenship_valid  ssn_valid_citizenship_invalid! ssn_valid_citizenship_invalid
                                ssn_valid! ssn_valid)
    RESIDENCY_VALID_EVENTS = %w(pass_residency!  pass_residency)

    IMMIGRATION_VALID_EVENTS = %w(pass_dhs! pass_dhs)

    ALL_EVENTS = %w(ssn_valid_citizenship_valid! ssn_valid_citizenship_valid ssn_valid_citizenship_invalid  ssn_valid_citizenship_invalid!
                  pass_dhs! pass_dhs)
    def date
      begin
        ENV["date"].strip         
      rescue
        puts 'Provide report month.'
      end
    end

    def subscriber_id
      if @person.primary_family
        @person.hbx_id
      else
        @person.families.map(&:primary_family_member).select{|member| member.person.consumer_role.present?}.first.hbx_id || @person.hbx_id
      end
    end

    def ivl_enrollment(person)
      if person.primary_family
        if person.primary_family.hbx_enrollments.individual_market.present?
          person.primary_family.hbx_enrollments.individual_market.select(&:currently_active?).any? ? "YES" : "NO"
        else
          "nil"
        end
      else
        families = person.families.select{|family| family.hbx_enrollments.individual_market.present?}
        enrollments = families.flat_map(&:hbx_enrollments).select{|enrollment| !enrollment.is_shop?} if families
        all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
        active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state)}
        return "nil" unless all_enrollments.any?
        active_enrollments.any? ? "YES" : "NO"
      end
    end

    def shop_enrollment(person)
      if person.primary_family
        if person.primary_family.hbx_enrollments.shop_market.present?
          person.primary_family.hbx_enrollments.shop_market.select(&:currently_active?).any? ? "YES" : "NO"
        else
          "nil"
        end
      else
        families = person.families.select{|family| family.hbx_enrollments.shop_market.present?}
        enrollments = families.flat_map(&:hbx_enrollments).select{|enrollment| !enrollment.is_shop?} if families
        all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
        active_enrollments = enrollments.select(&:currently_active?)
        return "nil" unless all_enrollments.any?
        active_enrollments.any? ? "YES" : "NO"
      end
    end


    def start_date
      Date.parse(date)
    end

    def end_date
      Date.parse(date).next_month
    end

    def type_history_elements_with_date_range(v_type)
      v_type.type_history_elements.
      where(created_at:{
        :"$gte" => start_date,
        :"$lt" => end_date},
        :"$or" => [
          {:"action" => "verify"},
          {:"modifier" => "external Hub"}
        ]
      ).uniq{|element| [element.modifier,element.created_at.to_date]}
    end
  
    def verified_people
      Person.where(:"verification_types.type_history_elements" => { :"$elemMatch" => {
        :"created_at" => {
          :"$gte" => start_date,
          :"$lt" => end_date
        },
        :"$or" => [
          {:"action" => "verify"},
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
          SSN_VALID_EVENTS
        when VerificationType::LOCATION_RESIDENCY
          RESIDENCY_VALID_EVENTS
        when 'Immigration status'
          IMMIGRATION_VALID_EVENTS
        when 'Citizenship'
          CITIZEN_VALID_EVENTS
        else
          ALL_EVENTS
      end
    end
    
   def is_not_eligible_transaction?(v_type)
      return false if @history_element.modifier != "external Hub"
      hub_response_wfst(v_type).blank?
    end


    file_name = "#{Rails.root}/public/verified_verification_report_#{date.gsub(" ", "").split(",").join("_")}.csv"


    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names

      verified_people.each do |person|
        begin
          @person = person
          person.verification_types.each do |v_type|
            type_history_elements_with_date_range(v_type).each do |history_element|
            @history_element = history_element
            next if is_not_eligible_transaction?(v_type)
            csv << [  subscriber_id,
                      person.hbx_id,
                      person.first_name,
                      person.last_name,
                      v_type.validation_status,
                      v_type.type_name,
                      history_element.created_at,
                      history_element.update_reason,
                      ivl_enrollment(person),
                      shop_enrollment(person)
            ]
            end
          end
        rescue => e
         puts "Invalid Person with HBX_ID: #{person.hbx_id}"
        end 
      end
      
      puts "*********** DONE ******************"
    end

  end
end
