# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class UpdateMember
      include EventSource::Command
      include Dry::Monads[:result, :do]

      def call(params)
        applicant_params, family_id, person = yield validate(params)
        member_hash = yield transform(applicant_params)
        person = yield assign_member_values(person, member_hash)
        active_vlp_document = yield find_active_vlp_document(person, member_hash)
        family = yield find_family(family_id)
        yield build_relationship(person, family, applicant_params[:relationship])
        family_member = yield build_family_member(person, family)
        family_member_id = yield persist(person, family, family_member, active_vlp_document)
        fire_consumer_roles_update_for_vlp_docs(person.consumer_role, person.consumer_role.is_applying_coverage) if person.consumer_role.present?

        Success(family_member_id)
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide applicant_params to build member") if params[:applicant_params].blank?
        return Failure("Provide person to build member") if params[:person].blank?

        Success([params[:applicant_params], params[:family_id].to_s, params[:person]])
      end

      def transform(applicant_params)
        Operations::People::TransformApplicantToMember.new.call(applicant_params)
      end

      def assign_member_values(person, member_hash)
        person.assign_attributes(member_hash)
        Success(person)
      end

      def find_active_vlp_document(person, member_hash)
        vlp_document = person.consumer_role.vlp_documents.detect { |doc| doc.subject.to_s == member_hash.dig(:consumer_role, :vlp_documents_attributes, 0, :subject).to_s }
        Success(vlp_document)
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
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

        existing_relationship = primary_person.person_relationships.where(kind: relationship_kind, relative_id: BSON::ObjectId(person.id.to_s)).first
        return Success() if existing_relationship

        primary_person.ensure_relationship_with(person, relationship_kind)
        Success()
      rescue StandardError => e
        Failure("Relationship creation failed: #{e}")
      end

      def persist(person, _family, family_member, active_vlp_document)
        person.consumer_role.active_vlp_document_id = active_vlp_document&.id

        if person.changes.present?
          person.save!
          family_member.save!
          return Success()
        end

        if consumer_role_changed?(person.consumer_role)
          person.consumer_role.save!
          family_member.save!
        end

        Success({family_member_id: family_member.id})
      end

      def consumer_role_changed?(consumer_role)
        consumer_role.changes.present? || consumer_role.vlp_documents.any?(&:changed?) || consumer_role.lawful_presence_determination.changes.present?
      end

      def fire_consumer_roles_update_for_vlp_docs(consumer_role, original_applying_for_coverage)
        event = event('events.individual.consumer_roles.updated', attributes: { gid: consumer_role.to_global_id.uri, previous: {is_applying_coverage: original_applying_for_coverage} })
        event.success.publish if event.success?
      rescue StandardError => e
        Rails.logger.error { "Couldn't generate consumer role updated event due to #{e.backtrace}" }
      end
    end
  end
end
