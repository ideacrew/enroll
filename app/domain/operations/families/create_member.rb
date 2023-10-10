# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class CreateMember
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        applicant_params, family_id = yield validate(params)
        member_hash = yield transform_applicant_to_member(applicant_params)
        person = yield build_member(member_hash)
        family = yield find_family(family_id)
        yield build_relationship(person, family, applicant_params[:relationship])
        yield build_family_member(person, family)
        yield persist(person, family)

        #send family member id
        Success("Family member created successfully")
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide applicant_params to build member") if params[:applicant_params].blank?
        Success([params[:applicant_params], params[:family_id].to_s])
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
      end

      def transform_applicant_to_member(applicant_params)
        result = Operations::People::TransformApplicantToMember.new.call(applicant_params)
        return result unless result.success?

        Success(result.success["consumer_role"].merge!(:is_applicant => false))
      end

      def build_member(member_hash)
        person = Person.new(member_hash)
        Success(person)
      end

      def build_family_member(person, family)
        family.build_family_member(person)
        Success()
      rescue StandardError => e
        Failure("Family member creation failed: #{e}")
      end

      def build_relationship(person, family, relationship_kind)
        primary_person = family.primary_person

        primary_person.ensure_relationship_with(person, relationship_kind) if primary_person.present?
        Success()
      rescue StandardError => e
        Failure("Relationship creation failed: #{e}")
      end

      def persist(person, family)
        person.save!
        family.save!
        Success({family_member_id: @family_member.id, person_hbx_id: @person.hbx_id})
      end
    end
  end
end
