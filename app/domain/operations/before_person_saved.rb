module Operations
 class BeforePersonSaved
  include Dry::Monads[:result, :do]

    # encrypted_ssn_change || first_name_change || last_name_change || dob_change
    # emails
    # phones
    # addresses
    CHANGED_ATTRIBUTES = {:first_name => :person_name, :last_name => :person_name, :dob => :person_demographics, :encrypted_ssn => :person_demographics, :changed_address_attributes => :addresses }

    def call(changed_attributes, family_member)
      values = yield validate(changed_attributes, family_member)
      build_cv3_family(values)
    end

    private

    def validate(changed_attributes, family_member)
      return Failure('changed attributes not present') if changed_attributes.empty?
      return Failure('cv3 family member not present') if family_member.nil?

      Success(changed_attributes: changed_attributes, family_member: family_member)
    end

    def build_cv3_family(values)
      
      changed_attributes = values[:changed_attributes]
      family_member = values[:family_member]

      person = family_member[:person]

      changed_person_attributes = changed_attributes[:changed_person_attributes]
      changed_address_attributes = changed_attributes[:changed_address_attributes]
      changed_phone_attributes = changed_attributes[:changed_phone_attributes]
      changed_email_attributes = changed_attributes[:changed_email_attributes]
      changed_person_relationship_attributes = changed_attributes[:changed_relationship_attributes]
      Rails.logger.info { "355 #{changed_attributes}" }
      # return Failure("No changed attributes detected for #{person[:hbx_id]}") if changed_person_attributes.empty? && changed_address_attributes.empty? && changed_phone_attributes.empty? && changed_email_attributes.empty?
      build_before_person_saved(person, changed_person_attributes)
      build_before_addresses_saved(person, changed_address_attributes)
      build_before_phone_saved(person, changed_phone_attributes)
      build_before_person_relationships_saved(person, changed_person_relationship_attributes)
      Success(person)
    end

    def build_before_person_saved(person, changed_person_attributes)
      Rails.logger.info { "45 #{changed_person_attributes}"}
      changed_person_attributes.keys.each do |key|
        if CHANGED_ATTRIBUTES.include?(key)
          attributes_to_merge = {key => changed_person_attributes[key]}
          person[CHANGED_ATTRIBUTES[key]].merge!(attributes_to_merge)
        else
          #! do something here
          # return Failure("Attributes not found in CHANGED_ATTRIBUTES")
        end
      end
    end

    def build_before_addresses_saved(person, changed_address_attributes)
      Rails.logger.info { changed_address_attributes.count }
      changed_address_attributes.each do |address|
        Rails.logger.info { "58 #{address[:kind]}" }
        if address.keys.present?
          
          person[:addresses].detect { |new_address| new_address[:kind] == address[:kind] }.merge!(address)
        end
      end
      # changed_person_attributes.keys.each do |key|
      #   if CHANGED_ATTRIBUTES.include?(key)
      #     attributes_to_merge = {key => changed_person_attributes[key]}
      #     person[CHANGED_ATTRIBUTES[key]].merge!(attributes_to_merge)
      #   else
      #     #! do something here
      #     # return Failure("Attributes not found in CHANGED_ATTRIBUTES")
      #   end
      # end
    end

    def build_before_phone_saved(person, changed_phone_attributes)
      changed_phone_attributes.each do |phone_attributes|
        if phone_attributes.keys.present?
          
          person[:phones].detect { |phone| phone[:kind] == phone_attributes[:kind] }.merge!(phone_attributes)
        end
      end
    end

    def build_before_person_relationships_saved(person, changed_person_relationships)
      Rails.logger.info { "89 #{changed_person_relationships}"}
      changed_person_relationships.each do |person_relationship_attributes|
        Rails.logger.info { "90 #{person[:person_relationships].first}"}
      end
    end


  end
end