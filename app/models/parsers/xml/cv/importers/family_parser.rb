module Parsers::Xml::Cv::Importers
  class FamilyParser
    attr_reader :family, :id, :e_case_id, :primary_family_member_id, :family_members, :households, :irs_groups

    def initialize(input_xml)
      @family = Openhbx::Cv2::Family.parse(input_xml, single: true)
      @id = family.id
      @e_case_id = family.e_case_id
      @primary_family_member_id = family.primary_family_member_id
      @family_members = family.family_members
      @households = family.households
      @irs_groups = family.irs_groups
    end

    def get_family_object
      family_member_objects = []
      if family_members
        family_members.each do |fm|
          family_member_objects << FamilyMember.new(
            id: fm.id,
            hbx_id: fm.id,
            former_family_id: fm.primary_family_id,
            is_primary_applicant: fm.is_primary_applicant.to_s == 'true', # did not see the real xml  
            is_coverage_applicant: fm.is_coverage_applicant.to_s == 'true', # need to confirm the case sensetive
            person: get_person_object_by_family_member_xml(fm),
          )
        end
      end
      household_objects = []
      if households
        households.each do |h|
          household_objects << Household.new(
            id: h.id,
            irs_group_id: h.irs_group_id,
            effective_starting_on: h.start_date,
            effective_ending_on: h.end_date,
            coverage_households: get_coverage_households_by_household_xml(h),
            tax_households: get_tax_households_by_household_xml(h),
          )
        end
      end
      irs_group_objects = []
      if irs_groups
        irs_groups.each do |irs|
          irs_group_objects << IrsGroup.new(
            hbx_assigned_id: irs.id,
            effective_starting_on: irs.effective_start_date,
            effective_ending_on: irs.effective_end_date,
          )
        end
      end
      Family.new(
        id: id,
        e_case_id: e_case_id,
        family_members: family_member_objects,
        households: household_objects,
        irs_groups: irs_group_objects,
      )
    end

    def get_person_object_by_family_member_xml(fm)
      person = fm.person
      person_demographics = fm.person_demographics
      person_relationships = fm.person_relationships
      hbx_id = person.id.match(/hbx_id#(.*)/)[1] rescue ''
      gender = person_demographics.sex.match(/gender#(.*)/)[1] rescue ''

      person_object = Person.new(
        hbx_id: hbx_id,
        first_name: person.first_name,
        middle_name: person.middle_name,
        last_name: person.last_name,
        name_pfx: person.name_prefix,
        name_sfx: person.name_suffix,
        ssn: person_demographics.ssn,
        dob: person_demographics.birth_date.try(:to_date),
        gender: gender,
        ethnicity: [person_demographics.ethnicity],
        language_code: person_demographics.language_code,
        race: person_demographics.race,
      )
      person_relationships.each do |relationship|
        person_object.person_relationships.build({
          relative_id: relationship.object_individual, #use subject_individual or object_individual
          kind: relationship.relationship_uri,
        })
      end
      person.addresses.each do |address|
        kind = address.type.match(/address_type#(.*)/)[1] rescue 'home'
        person_object.addresses.build({
          address_1: address.address_line_1,
          address_2: address.address_line_2,
          city: address.location_city_name,
          state: address.location_state_code,
          zip: address.postal_code,
          kind: kind,
        })
      end
      person.phones.each do |phone|
        phone_type = phone.type
        phone_type_for_enroll = phone_type.blank? ? nil : phone_type.strip.split("#").last
        if Phone::KINDS.include?(phone_type_for_enroll)
          person_object.phones.build({
            kind: phone_type_for_enroll,
            full_phone_number: phone.full_phone_number
          })
        end
      end
      person.emails.each do |email|
        email_type = email.type
        email_type_for_enroll = email_type.blank? ? nil : email_type.strip.split("#").last
        if ["home", "work"].include?(email_type_for_enroll)
          person_object.emails.build({
            :kind => email_type_for_enroll,
            :address => email.email_address
          })
        end 
      end

      person_object
    end

    def get_coverage_households_by_household_xml(household)
      coverage_households = []
      household.coverage_households.each do |ch|
        coverage_households << CoverageHousehold.new(
          id: ch.id,
          is_immediate_family: ch.is_immediate_family == 'true',
        )
      end

      coverage_households
    end

    def get_tax_households_by_household_xml(household)
      tax_households = []
      household.tax_households.each do |th|
        tax_household_members = []
        th.tax_household_members.each do |thm|
          tax_household_members << TaxHouseholdMember.new(
            applicant_id: thm.id,
            is_ia_eligible: thm.is_insurance_assistance_eligible == 'true',
            is_medicaid_chip_eligible: thm.is_medicaid_chip_eligible == 'true',
          )
        end
        tax_households << TaxHousehold.new(
          id: th.id,
          tax_household_members: tax_household_members,
          effective_starting_on: th.start_date,
          effective_ending_on: th.end_date,
        )
      end

      tax_households
    end
  end
end
