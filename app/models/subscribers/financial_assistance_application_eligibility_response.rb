module Subscribers
  class FinancialAssistanceApplicationEligibilityResponse < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      ["acapi.info.events.assistance_application.application_processed"]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      stringed_key_payload = payload.stringify_keys
      xml = stringed_key_payload["body"]

      application = FinancialAssistance::Application.find(stringed_key_payload["assistance_application_id"]) if stringed_key_payload["assistance_application_id"].present?
      if application.present?
        payload_http_status_code = stringed_key_payload["return_status"]
        unless application.success_status_codes?(payload_http_status_code.to_i)
          error_message = stringed_key_payload["body"]
          application.set_determination_response_error!
        end
        application.update_attributes(determination_http_status_code: payload_http_status_code, determination_error_message: error_message)
      else
        log(stringed_key_payload, {:severity => "critical", :error_message => "Failed to find the Application in XML"})
      end

      log(stringed_key_payload, {:severity => "critical", :error_message => "Testing Purpose"})

      sc = ShortCircuit.on(:processing_issue) do |err|
        log(xml, {:severity => "critical", :error_message => err})
      end
      sc.and_then do |payload|
        haven_import_from_xml(payload)
      end
      sc.call(xml)
    end

    def ecase_id_valid?(family, verified_family)
      !family.e_case_id.present? || (family.e_case_id.include? "curam_landing") || family.e_case_id == verified_family.integrated_case_id
    end

    def haven_import_from_xml(xml)
      verified_family = Parsers::Xml::Cv::HavenVerifiedFamilyParser.new
      verified_family.parse(xml)
      verified_primary_family_member = verified_family.family_members.detect{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
      verified_dependents = verified_family.family_members.reject{ |fm| fm.person.hbx_id == verified_family.primary_family_member_id }
      primary_person = search_person(verified_primary_family_member)
      throw(:processing_issue, "ERROR: Failed to find primary person in xml") unless primary_person.present?
      family = primary_person.primary_family
      throw(:processing_issue, "ERROR: Failed to find primary family for users person in xml") unless family.present?
      stupid_family_id = family.id
      active_household = family.active_household
      family.save! # In case the tax household does not exist
      #        family = Family.find(stupid_family_id) # wow
      #        active_household = family.active_household

      application_in_context = family.applications.find(verified_family.fin_app_id)
      throw(:processing_issue, "ERROR: Failed to find application for person in xml") unless application_in_context.present?

      active_verified_household = verified_family.households.max_by(&:start_date)

      verified_dependents.each do |verified_family_member|
        throw(:processing_issue, "Failed to find dependent from xml") unless search_person(verified_family_member).present?
      end

      if verified_family.broker_accounts.present?
        newest_broker = verified_family.broker_accounts.max_by{ |broker| broker.start_on}
        newest_broker_agency_account = family.broker_agency_accounts.max_by{ |baa| baa.start_on }
        if !newest_broker_agency_account.present? || newest_broker.start_on > newest_broker_agency_account.start_on
          update_broker_for_family(family, newest_broker.broker_npn)
        end
      end

      primary_person = search_person(verified_primary_family_member) #such mongoid
      family.save!

      family.e_case_id = verified_family.integrated_case_id
      begin
        application_in_context.build_or_update_tax_households_and_applicants_and_eligibility_determinations(verified_family, primary_person, active_verified_household)
      rescue
        throw(:processing_issue, "Failure to update tax household")
      end

      begin
        if application_in_context.tax_households.present?
          unless application_in_context.eligibility_determinations.present?
            log("ERROR: No eligibility_determinations found for tax_household: #{xml}", {:severity => "error"})
          end
        end
      rescue
        log("ERROR: Unable to create tax household from xml: #{xml}", {:severity => "error"})
      end
      family.save!
      application_in_context.determine!
    end

    def update_vlp_for_consumer_role(consumer_role, verified_primary_family_member )
      begin
        verified_verifications = verified_primary_family_member.verifications
        consumer_role.import
        consumer_role.pass_ssn
        consumer_role.vlp_authority = "curam"
        consumer_role.residency_determined_at = verified_primary_family_member.created_at
        consumer_role.citizen_status = verified_verifications.citizen_status.split('#').last
        consumer_role.is_state_resident = verified_verifications.is_lawfully_present
        consumer_role.is_incarcerated = verified_primary_family_member.person_demographics.is_incarcerated
        consumer_role.save!
        if consumer_role.person.user.present?
          consumer_role.person.user.ridp_by_payload!
        end
      rescue => e
        errors_list = consumer_role.errors.full_messages + [e.message] + e.backtrace
        throw(:processing_issue, "Unable to update consumer vlp: #{errors_list.join("\n")}")
      end
    end

    def import_home_address(person, verified_new_address)
      verified_address_hash = verified_new_address.to_hash
      verified_address_hash.delete(:country)
      new_address = Address.new(
        verified_address_hash
      )
      throw(:processing_issue, "ERROR: Failed to load home address from xml") unless new_address.valid?
      if person.home_address.present?
        person.home_address.delete
      end
      person.addresses << new_address
      person.save!
    end

    def find_or_create_new_members(verified_dependents, verified_primary_family_member)
      new_people = []
      if verified_dependents.present?
        verified_dependents.each do |verified_family_member|
          existing_person = search_person(verified_family_member)
          successor_id = Person.where(hbx_id: verified_family_member.person.hbx_id).first.id
          primary_person = Person.where(hbx_id: verified_primary_family_member.person.hbx_id).first
          relationship = primary_person.person_relationships.where(successor_id: successor_id).first.kind

          # #Person Relationships
          # relationship = verified_primary_family_member.person_relationships.select do |pr|
          #   pr.object_individual_id == verified_family_member.id &&
          #     pr.subject_individual_id == verified_primary_family_member.id
          # end.first.relationship_uri.split('#').last

          # relationship = PersonRelationship::InverseMap[relationship]

          if existing_person.present?
            find_or_build_consumer_role(existing_person)
            # update_vlp_for_consumer_role(existing_person.consumer_role, verified_family_member)
            new_people << [existing_person, relationship, [verified_family_member.id]]
                                  #TODO New Dependents intake.
                                  # else
                                  #   new_member = Person.new(
                                  #     first_name: verified_family_member.person.name_first,
                                  #     last_name: verified_family_member.person.name_last,
                                  #     middle_name: verified_family_member.person.name_middle,
                                  #     name_pfx: verified_family_member.person.name_pfx,
                                  #     name_sfx: verified_family_member.person.name_sfx,
                                  #     dob: verified_family_member.person_demographics.birth_date,
                                  #     ssn: verified_family_member.person_demographics.ssn == "999999999" ? "" : verified_family_member.person_demographics.ssn ,
                                  #     gender: verified_family_member.person_demographics.sex.split('#').last
                                  #   )
                                  #   new_member.save!
                                  #   find_or_build_consumer_role(new_member)
                                  #   # update_vlp_for_consumer_role(new_member.consumer_role, verified_family_member)
                                  #   verified_new_address = verified_family_member.person.addresses.select{|adr| adr.type.split('#').last == "home" }.first
                                  #   # import_home_address(new_member, verified_new_address)
                                  #   new_people << [new_member, relationship, [verified_family_member.id]]
          end
        end
      end
      new_people
    end

    def update_broker_for_family(family, npn)
      broker = BrokerRole.find_by_npn(npn)
      if broker.present?
        if broker.broker_agency_profile_id.present?
          family.hire_broker_agency(broker.id)
        else
          throw(:processing_issue, "ERROR: Broker with npn: #{npn} has no broker agency profile id")
        end
      else
        throw(:processing_issue, "ERROR: Failed to match broker with npn: #{npn}")
      end
    end

    def find_or_build_consumer_role(person)
      return person.consumer_role if person.consumer_role.present?
      person.build_consumer_role(is_applicant: true)
    end

    def search_person(verified_family_member)
      ssn = verified_family_member.person_demographics.ssn
      ssn = '' if ssn == "999999999"
      dob = verified_family_member.person_demographics.birth_date
      dob = Date.strptime( dob , '%Y%m%d')
      last_name_regex = /^#{verified_family_member.person.name_last}$/i
      first_name_regex = /^#{verified_family_member.person.name_first}$/i

      #Verify how it is comparing the dob string to a date format.
      if !ssn.blank?
        Person.where({
          :encrypted_ssn => Person.encrypt_ssn(ssn),
          :dob => dob
        }).first
      else
        Person.where({
          :dob => dob,
          :last_name => last_name_regex,
          :first_name => first_name_regex
        }).first
      end
    end
  end
end
