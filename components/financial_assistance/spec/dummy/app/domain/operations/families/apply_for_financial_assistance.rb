# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    class ApplyForFinancialAssistance
      include Dry::Monads[:result, :do]

      def call(family_id:)
        family = yield find_family(family_id)
        execute(family: family)
      end

      private

      def find_family(family_id)
        family = Family.find(family_id)
        Success(family)
      rescue
        Failure('Cannot find family')
      end

      def execute(family:)
        Success(family.active_family_members.collect {|family_member| family_member_attributes(family_member)})
      end

      def family_member_attributes(family_member)
        person_attributes(family_member.person, family_member.family).merge(family_member_id: family_member.id,
                                                                            is_primary_applicant: family_member.is_primary_applicant,
                                                                            is_consent_applicant: family_member.is_consent_applicant)
      end

      def person_attributes(person, family)
        attrs = person.attributes.slice(:first_name,
                                        :last_name,
                                        :middle_name,
                                        :name_pfx,
                                        :name_sfx,
                                        :gender,
                                        :ethnicity,
                                        :tribal_id,
                                        :tribal_state,
                                        :tribal_name,
                                        :no_ssn,
                                        :is_tobacco_user).symbolize_keys!

        attrs.merge({person_hbx_id: person.hbx_id,
                     ssn: person.ssn,
                     dob: person.dob.strftime("%d/%m/%Y"),
                     is_applying_coverage: person.consumer_role.is_applying_coverage,
                     citizen_status: person.citizen_status,
                     relationship: get_relationship_kind(family, person),
                     is_consumer_role: true,
                     same_with_primary: false,
                     indian_tribe_member: person.consumer_role.is_tribe_member?,
                     is_incarcerated: person.is_incarcerated,
                     addresses: construct_association_fields(person.addresses),
                     phones: construct_association_fields(person.phones),
                     emails: construct_association_fields(person.emails)})
      end

      def get_relationship_kind(family, person)
        family.primary_person.find_relationship_with(person)
      end

      def construct_association_fields(records)
        records.collect{|record| record.attributes.except(:_id, :created_at, :updated_at, :tracking_version, :location_state_code, :full_text) }
      end
    end
  end
end
