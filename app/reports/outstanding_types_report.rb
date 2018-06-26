require File.join(Rails.root, "lib/mongoid_migration_task")
require 'csv'

class OutstandingTypesReport < MongoidMigrationTask
  def ivl_enrollment(person)
    if person.primary_family
      if person.primary_family.active_household.hbx_enrollments.individual_market.present?
        person.primary_family.active_household.hbx_enrollments.individual_market.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year) }.any? ? "YES" : "NO"
      else
        "nil"
      end
    else
      families = person.families.select{|family| family.active_household.hbx_enrollments.individual_market.present?}
      enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| !(["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
      all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
      active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year)}
      return "nil" unless all_enrollments.any?
      active_enrollments.any? ? "YES" : "NO"
    end
  end

  def outstanding_verification_types(person)
    verification_types(person).find_all do |type|
      is_type_outstanding?(person, type)
    end
  end

  def verification_types(person)
    verification_types = []
    verification_types << 'DC Residency'
    verification_types << 'Social Security Number' if person.ssn
    verification_types << 'American Indian Status' if !(person.tribal_id.nil? || person.tribal_id.empty?)
    if person.us_citizen
      verification_types << 'Citizenship'
    else
      verification_types << 'Immigration status'
    end
    verification_types
  end

  def is_type_outstanding?(person, type)
    case type
    when "DC Residency"
      person.consumer_role.residency_denied?
    when 'Social Security Number'
      !person.consumer_role.ssn_verified?
    when 'American Indian Status'
      !person.consumer_role.native_verified?
    else
      !person.consumer_role.lawful_presence_authorized?
    end
  end

  def created_at(person)
    transition = person.consumer_role.workflow_state_transitions.where(:to_state => "verification_outstanding").order_by(:created_at => 'desc').first
    if transition
      transition.transition_at
    else
      person.consumer_role.created_at
    end
  end

  def shop_enrollment(person)
    if person.primary_family
      if person.primary_family.active_household.hbx_enrollments.shop_market.present?
        person.primary_family.active_household.hbx_enrollments.shop_market.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year) }.any? ? "YES" : "NO"
      else
        "nil"
      end
    else
      families = person.families.select{|family| family.active_household.hbx_enrollments.shop_market.present?}
      enrollments = families.flat_map(&:active_household).flat_map(&:hbx_enrollments).select{|enrollment| (["employer_sponsored", "employer_sponsored_cobra"].include? enrollment.kind)} if families
      all_enrollments = enrollments.select{|enrollment| enrollment.hbx_enrollment_members.map(&:person).map(&:id).include?(person.id) }
      active_enrollments = enrollments.select{|enrollment| HbxEnrollment::ENROLLED_STATUSES.include?(enrollment.aasm_state) && enrollment.effective_on.between?(TimeKeeper.date_of_record.beginning_of_year,TimeKeeper.date_of_record.end_of_year)}
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

  def due_date_for_type(person, type, type_created)
    if person.consumer_role.special_verifications.any?
      sv = person.consumer_role.special_verifications.order_by(:created_at => 'desc').select{|sv| sv.verification_type == type }.first
      sv.present? ? sv.due_date : type_created + 95.days
    else
      type_created + 95.days
    end
  end

  def no_active_enrollments(person)
    return true if person.families.empty?
    person.families.select{|f| f.person_has_an_active_enrollment?(person)}.empty?
  end

  def people
    Person.where(:"consumer_role.aasm_state" => "verification_outstanding")
  end

  def migrate
    field_names = %w( SUBSCRIBER_ID MEMBER_ID FIRST_NAME LAST_NAME VERIFICATION_TYPE TRANSITION OUTSTANDING DUE_DATE IVL_ENROLLMENT SHOP_ENROLLMENT)
    file_name = "#{Rails.root}/app/reports/outstanding_types_report.csv"
    CSV.open(file_name, "w", force_quotes: true) do |csv|
      csv << field_names
      people.each do |person|
        next if no_active_enrollments(person)
        if outstanding_verification_types(person).any?
          outstanding_verification_types(person).each do |type|
            csv << [
                subscriber_id(person),
                person.hbx_id,
                person.first_name,
                person.last_name,
                type,
                created_at(person).to_date,
                "yes",
                due_date_for_type(person, type, created_at(person)).to_date,
                ivl_enrollment(person),
                shop_enrollment(person)
            ]
          end
        end
      end
    end
    puts "*********** DONE ******************" unless Rails.env.test?
  end
end
