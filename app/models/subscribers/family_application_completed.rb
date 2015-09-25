module Subscribers
  class FamilyApplicationCompleted < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
        ["acapi.info.events.family.application_completed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]
      import_from_xml(xml)
    end

    def import_from_xml(xml)
      verified_family = Parsers::Xml::Cv::VerifiedFamilyParser.new
      verified_family.parse(xml)
      verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.id == verified_family.primary_family_member_id }
      verified_dependents = verified_family.family_members.reject{ |fm| fm.id == verified_family.primary_family_member_id }
      primary_person = search_person(verified_primary_family_member)
      family = find_existing_family(verified_primary_family_member, primary_person, xml)

      if family.present? && family.e_case_id == verified_family.integrated_case_id
        log("ERROR: Integrated case id already exists in another family for xml: #{xml}", {:severity => "error"})
      elsif family.present?
        begin
          active_household = family.active_household
          family.e_case_id = verified_family.integrated_case_id
          active_verified_household = verified_family.households.select{|h| h.integrated_case_id == verified_family.integrated_case_id}.first
          active_verified_tax_household = active_verified_household.tax_households.select{|th| th.primary_applicant_id == verified_primary_family_member.id.split('#').last}.first
          new_dependents = find_or_create_new_members(verified_dependents, verified_primary_family_member)
          verified_new_address = verified_primary_family_member.person.addresses.select{|adr| adr.type.split('#').last == "home" }.first
          import_home_address(primary_person, verified_new_address)
          active_household.build_or_update_tax_household_from_primary(verified_primary_family_member, primary_person, active_verified_household)
          update_vlp_for_consumer_role(primary_person.consumer_role, verified_primary_family_member)
          new_dependents.each do |p|
            new_family_member = family.relate_new_member(p[0], p[1])
            if active_verified_tax_household.present?
              new_tax_household_member = active_verified_tax_household.tax_household_members.select{|thm| thm.id == p[2][0]}.first
              active_household.add_tax_household_family_member(new_family_member,new_tax_household_member)
            end
            family.save!
          end
        rescue
          log("ERROR: Unable to create tax household from xml: #{xml}", {:severity => "error"})
        end
        family.save!
      else
        log("ERROR: Failed to find primary family for users person in xml: #{xml}", {:severity => "error"})
      end
    end

    def update_vlp_for_consumer_role(consumer_role, verified_primary_family_member )
      verified_verifications = verified_primary_family_member.verifications
      consumer_role.import
      consumer_role.vlp_authority = "curam"
      consumer_role.residency_determined_at = verified_primary_family_member.created_at
      consumer_role.citizen_status = verified_verifications.citizen_status.split('#').last
      consumer_role.is_state_resident = verified_verifications.is_lawfully_present
      consumer_role.is_incarcerated = verified_primary_family_member.person_demographics.is_incarcerated
      consumer_role.save!
    end

    def import_home_address(person, verified_new_address)
      verified_address_hash = verified_new_address.to_hash
      verified_address_hash.delete(:country)
      new_address = Address.new(
        verified_address_hash
      )
      if new_address.valid?
        person.addresses << new_address
        person.save!
      else
        log("ERROR: Failed to load home address from xml: #{xml}", {:severity => "error"})
      end
    end

    def find_or_create_new_members(verified_dependents, verified_primary_family_member)
      new_people = []
      if verified_dependents.present?
        verified_dependents.each do |verified_family_member|
          existing_person = search_person(verified_family_member)
          relationship = verified_primary_family_member.person_relationships.select{|pr| pr.object_individual_id == verified_family_member.id}.first.relationship_uri.split('#').last

          if existing_person.present?
            new_people << [existing_person, relationship, [verified_family_member.id]]
          else
            new_member = Person.new(
              first_name: verified_family_member.person.name_first,
              last_name: verified_family_member.person.name_last,
              middle_name: verified_family_member.person.name_middle,
              name_pfx: verified_family_member.person.name_pfx,
              name_sfx: verified_family_member.person.name_sfx,
              dob: verified_family_member.person_demographics.birth_date,
              ssn: verified_family_member.person_demographics.ssn == "999999999" ? "" : verified_family_member.person_demographics.ssn ,
              gender: verified_family_member.person_demographics.sex.split('#').last
            )
            new_member.save!
            verified_new_address = verified_family_member.person.addresses.select{|adr| adr.type.split('#').last == "home" }.first
            import_home_address(new_member, verified_new_address)
            new_people << [new_member, relationship, [verified_family_member.id]]
          end
        end
      end
      new_people
    end

    def find_existing_family(verified_dependents_member, person, xml)
      family = nil
      unless person.present?
        log("ERROR: No person found for user in xml: #{xml}", {:severity => "error"})
      else
        family = person.primary_family
      end
      family
    end

    def search_person(verified_family_member)
      ssn = verified_family_member.person_demographics.ssn
      ssn = "" if ssn == "999999999"
      dob = verified_family_member.person_demographics.birth_date
      last_name = verified_family_member.person.name_last

      if !ssn.blank?
        Person.where({
                       :dob => dob,
                       :encrypted_ssn => Person.encrypt_ssn(ssn)
                   }).first
      else
        Person.where({
                       :dob => dob,
                       :last_name => last_name
                   }).first
      end
    end
  end
end
