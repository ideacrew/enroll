require File.join(Rails.root, "lib/mongoid_migration_task")

class MigrateVerificationTypes < MongoidMigrationTask
  def get_people
    Person.where(:"consumer_role" => {"$exists" => true})
  end

  def migrate
    people = get_people
    people.each do |person|
      begin
        ensure_verification_types(person)
        # person.verification_types.each do |type|
        #   assign_verification_type_status(type, person)
        # end
        puts "Person HBX_ID: #{person.hbx_id} verification_types where moved" unless Rails.env.test?
      rescue
        $stderr.puts "Issue migrating person: person #{person.id}, HBX id  #{person.hbx_id}"
      end
    end
  end

  def ensure_verification_types(person)
    live_types = []
    live_types << 'DC Residency'
    live_types << 'Social Security Number' if person.ssn
    live_types << 'American Indian Status' if !(person.tribal_id.nil? || person.tribal_id.empty?)
    if person.us_citizen
      live_types << 'Citizenship'
    else
      live_types << 'Immigration status'
    end
    person.verification_types.delete_all
    live_types.each do |type|
      add_new_verification_type(person, type)
    end
  end

  def add_new_verification_type(person, type)
    person.verification_types << VerificationType.new(
        :type_name => type,
        :validation_status => assign_verification_type_status(type, person),
        :update_reason => type_update_reason(person, type),
        :rejected => type_rejected(person, type),
        :due_date => due_date_for_type(person, type))
  end

  def due_date_for_type(person, type)
    sv=person.consumer_role.special_verifications.where(verification_type: type).order_by(:"created_at".desc).first
    sv.due_date if sv.present?
  end

  def type_rejected(person, type)
    case type
      when 'DC Residency'
        person.consumer_role.residency_update_reason
      when 'Social Security Number'
        person.consumer_role.ssn_rejected
      when 'American Indian Status'
        person.consumer_role.native_rejected
      when 'Citizenship'
        person.consumer_role.lawful_presence_rejected
      when 'Immigration status'
        person.consumer_role.lawful_presence_rejected
    end
  end

  def type_update_reason(person, type)
    case type
      when 'DC Residency'
        person.consumer_role.residency_update_reason
      when 'Social Security Number'
        person.consumer_role.ssn_update_reason
      when 'American Indian Status'
        person.consumer_role.native_update_reason
      when 'Citizenship'
        reason = person.consumer_role.lawful_presence_update_reason
        person.consumer_role.lawful_presence_update_reason[:update_reason] if reason && reason[:v_type] == 'Citizenship'
      when 'Immigration status'
        reason = person.consumer_role.lawful_presence_update_reason
        person.consumer_role.lawful_presence_update_reason[:update_reason] if reason && reason[:v_type] == 'Immigration status'
    end
  end


  def assign_verification_type_status(type, person)
    consumer = person.consumer_role
    if (consumer.vlp_authority == "curam" && consumer.fully_verified?)
      "curam"
    else
      case type
        when 'Social Security Number'
          if consumer.ssn_verified?
            "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.ssn_rejected
            "review"
          elsif consumer.ssa_pending?
            "processing"
          else
            "outstanding"
          end
        when 'American Indian Status'
          if consumer.native_verified?
            "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.native_rejected
            "review"
          else
            "outstanding"
          end
        when 'DC Residency'
          if consumer.residency_verified?
            consumer.residency_attested? ? "attested" : "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.residency_rejected
            "review"
          elsif consumer.residency_pending?
            "processing"
          else
            "outstanding"
          end
        else
          if consumer.lawful_presence_verified?
            "verified"
          elsif consumer.has_docs_for_type?(type) && !consumer.lawful_presence_rejected
            "review"
          elsif consumer.citizenship_immigration_processing?
            "processing"
          else
            "outstanding"
          end
      end
    end
  end
end