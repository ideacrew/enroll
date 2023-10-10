# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class UpdateMember
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        applicant_params, family_id, person = yield validate(params)
        member_hash = yield transform_applicant_to_member(applicant_params)
        person = yield assign_member_values(person, member_hash)
        family = yield find_family(family_id)
        yield build_relationship(person, family, applicant_params[:relationship])
        family_member = yield build_family_member(person, family)
        family_member_id = yield persist(person, family, family_member)
        Success(family_member_id)
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide applicant_params to build member") if params[:applicant_params].blank?
        return Failure("Provide person to build member") if params[:person].blank?

        Success([params[:applicant_params], params[:family_id].to_s, params[:person]])
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
      end

      def transform_applicant_to_member(applicant_params)
        Operations::People::TransformApplicantToMember.new.call(applicant_params)
      end

      def assign_member_values(person, member_hash)
        person.assign_attributes(member_hash)
        Success(person)
      end

      def build_family_member(person, family)
        family_member = family.build_family_member(person)

        Success(family_member)
      rescue StandardError => e
        Failure("Family member creation failed: #{e}")
      end

      def build_relationship(person, family, relationship_kind)
        primary_person = family.primary_person
        return Failure("Primary person not found") if primary_person.blank?

        exiting_relationship = primary_person.person_relationships.find_by(kind: relationship_kind, relative_id: BSON::ObjectId(person.id.to_s))
        return Success() if exiting_relationship

        primary_person.ensure_relationship_with(person, relationship_kind)
        Success()
      rescue StandardError => e
        Failure("Relationship creation failed: #{e}")
      end

      def persist(person, family, family_member)
        if person.changed?
          person.save!
          family.save!
          return Success()
        end

        if person.consumer_role.changed? || person.consumer_role.vlp_documents.any?(&:changed?) || person.consumer_role.lawful_presence_determination.changed?
          person.consumer_role.save!
          family.save!
        end
        family.reload
        family_member = family.detect{|fm| fm.id.to_s == family_member.id.to_s}

        Success({family_member_id: family_member.id})
      end
    end
  end
end
