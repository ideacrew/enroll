# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class CreateMember
      include EventSource::Command
      include Dry::Monads[:result, :do]

      # Creates a new family member.
      #
      # @param params [Hash] The parameters for creating the family member.
      # @option params [Hash] :member_params The parameters to create member.
      # @option params [String] :family_id The ID of the family.
      # @return [Dry::Monads::Result] The result of the operation is family_member_id.
      def call(params)
        member_params, family_id = yield validate(params)
        person = yield build_member(member_params)
        family = yield find_family(family_id)
        yield build_relationship(person, family, member_params[:relationship])
        family_member = yield build_family_member(person, family)
        person = yield persist_person(person)
        family_member_id = yield persist_family(family_member, family)
        event = yield build_event(person.consumer_role)
        yield fire_created_event(event)

        Success(family_member_id)
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide member_params to build member") if params[:member_params].blank?

        Success([params[:member_params], params[:family_id].to_s])
      end

      def find_family(family_id)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
      end

      def build_member(member_hash)
        person = Person.new(member_hash)
        Success(person)
      rescue StandardError => e
        Failure("Person build failed: #{e}")
      end

      def persist_person(person)
        consumer_role = person.consumer_role
        vlp_document = person.consumer_role.vlp_documents.first
        consumer_role.active_vlp_document_id = vlp_document.id if vlp_document.present?
        person.save!

        Success(person)
      rescue StandardError => e
        Failure("Person creation failed: #{e}")
      end

      def build_family_member(person, family)
        family_member = family.build_family_member(person)
        Success(family_member)
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

      def persist_family(family_member, family)
        family_member.save!

        family.active_household.coverage_households.each { |ch| ch.save! if ch.changed? }
        # family.save!
        Success(family_member.id)
      end

      def build_event(consumer_role)
        event('events.individual.consumer_roles.created', attributes: { gid: consumer_role.to_global_id.uri })
      end

      def fire_created_event(event)
        Success(event.publish)
      end
    end
  end
end
