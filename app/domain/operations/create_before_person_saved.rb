module Operations
 class CreateBeforePersonSaved
  include Dry::Monads[:result, :do]

    CHANGED_PERSON_ATTRIBUTES = {:first_name => :person_name, :last_name => :person_name, :dob => :person_demographics, :encrypted_ssn => :person_demographics}

    def call(changed_attributes, family_member)
      values = yield validate(changed_attributes, family_member)
      build_before_save_cv3_family(values)
    end

    private

    def validate(changed_attributes, family_member)
      return Failure('changed attributes not present') if changed_attributes.empty?
      return Failure('cv3 family member not present') if family_member.empty?

      Success(changed_attributes: changed_attributes, family_member: family_member)
    end

    def build_before_save_cv3_family(values)
      
      changed_attributes = values[:changed_attributes]
      family_member = values[:family_member]

      person = family_member[:person]

      changed_person_attributes = changed_attributes[:changed_person_attributes]
      changed_address_attributes = changed_attributes[:changed_address_attributes]
      changed_phone_attributes = changed_attributes[:changed_phone_attributes]
      changed_email_attributes = changed_attributes[:changed_email_attributes]
      changed_person_relationship_attributes = changed_attributes[:changed_relationship_attributes]
      build_before_person_saved(person, changed_person_attributes)
      build_before_addresses_saved(person, changed_address_attributes)
      build_before_phone_saved(person, changed_phone_attributes)
      build_before_emails_saved(person, changed_email_attributes)
      build_before_person_relationships_saved(person, changed_person_relationship_attributes)
      Success(family_member)
    rescue StandardError => e
      Rails.logger.error { "Failed to build before save cv3 family due to #{e.message} backtrace: #{e.backtrace.join("\n")}" }
      Failure( "Failed to build before save cv3 family due to #{e.message} backtrace: #{e.backtrace.join("\n")}")
    end

    def build_before_person_saved(person, changed_person_attributes)
      changed_person_attributes.keys.each do |key|
        if CHANGED_PERSON_ATTRIBUTES.include?(key)
          attributes_to_merge = {key => changed_person_attributes[key]}
          person[CHANGED_PERSON_ATTRIBUTES[key]]&.merge!(attributes_to_merge)
        end
      end
    end

    def build_before_addresses_saved(person, changed_address_attributes)
      changed_address_attributes.each do |address|
        Rails.logger.info { "58 #{address[:kind]}" }
        if address.keys.present?
          person[:addresses].detect { |new_address| new_address[:kind] == address[:kind] }&.merge!(address)
        end
      end
    end

    def build_before_phone_saved(person, changed_phone_attributes)
      changed_phone_attributes.each do |phone_attributes|
        if phone_attributes.keys.present?
          person[:phones].detect { |phone| phone[:kind] == phone_attributes[:kind] }&.merge!(phone_attributes)
        end
      end
    end

    def build_before_emails_saved(person, changed_email_attributes)
      changed_email_attributes.each do |email_attributes|
        if email_attributes.keys.present?
          person[:emails].detect { |email| email[:kind] == email_attributes[:kind] }&.merge!(email_attributes)
        end
      end
    end

    def build_before_person_relationships_saved(person, changed_person_relationships)
      changed_person_relationships.each do |person_relationship_attributes|
        relative_id = person_relationship_attributes[:relative_id]
        next unless relative_id.present?
        relative = Person.find(relative_id)
        person_relationship = person[:person_relationships].detect { |relationship| relationship[:relative][:hbx_id] == relative&.hbx_id }
        person_relationship&.merge!({:kind => person_relationship_attributes[:kind]})
        person_relationship[:relative]&.merge!({:relationship_to_primary => person_relationship_attributes[:kind]}) 
      end
    end
  end
end
