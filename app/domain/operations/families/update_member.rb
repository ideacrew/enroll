# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class UpdateMember
      include EventSource::Command
      include Dry::Monads[:result, :do]

      # Creates or updates a family member and persists the changes to the database.
      #
      # @param params [Hash] The parameters for creating or updating the family member.
      # @option params [Hash] :applicant_params The parameters for the applicant.
      # @option params [String] :family_id The ID of the family to which the member belongs.
      # @option params [Person] :person The person object to update.
      # @return [Dry::Monads::Result] A monad indicating success or failure.
      def call(params)
        applicant_params, family_id, person = yield validate(params)
        member_hash = yield transform(applicant_params)
        member_hash = yield sanitize_person_params(member_hash, person)
        person = yield assign_member_values(person, member_hash)
        active_vlp_document = yield find_active_vlp_document(person, member_hash)
        family = yield find_family(family_id)
        yield build_relationship(person, family, applicant_params[:relationship])
        family_member = yield build_family_member(person, family)
        result = yield persist(person, family_member, active_vlp_document)
        fire_update_event(result[:event]) if person.consumer_role.present? && result[:can_trigger_hub_call]

        Success(family_member.id)
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide applicant_params to build member") if params[:applicant_params].blank?
        return Failure("Provide person id to build member") if params[:person].blank?

        Success([params[:applicant_params], params[:family_id].to_s, params[:person]])
      end

      def transform(applicant_params)
        Operations::People::TransformApplicantToMember.new.call(applicant_params)
      end

      # Person object is storing the values as empty string
      # Applicant object is storing the values as nil
      # Sanitizes the member parameters to ensure that the person object is not overwritten with no values again.
      #
      # @param member_hash [Hash] The member parameters to sanitize.
      # @param person [Person] The person object to update.
      # @return [Dry::Monads::Result] A monad indicating success or failure.
      def sanitize_person_params(member_hash, person)
        member_hash[:tribal_name] = person.tribal_name if person.tribal_name.to_s.empty? && member_hash[:tribal_name].to_s.empty?
        member_hash[:tribal_state] = person.tribal_state if person.tribal_state.to_s.empty? && member_hash[:tribal_state].to_s.empty?
        member_hash[:ethnicity] = person.ethnicity if empty_array?(person.ethnicity) && empty_array?(member_hash[:ethnicity])
        member_hash[:tribe_codes] = person.tribe_codes if empty_array?(person.tribe_codes) && empty_array?(member_hash[:tribe_codes])

        Success(member_hash)
      end

      def empty_array?(array)
        array.all? { |value| value.nil? || value.empty? }
      end

      def assign_member_values(person, member_hash)
        person.assign_attributes(member_hash)

        Success(person)
      end

      # Finds the active VLP document for the person.
      #
      # active vlp document from applicant params
      def find_active_vlp_document(person, member_hash)
        subject = member_hash.dig(:consumer_role, :immigration_documents_attributes, 0, :subject).to_s
        vlp_document = person.consumer_role.vlp_documents.detect { |doc| doc.subject.to_s == subject }

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

      # Persists the changes to the person, consumer role, vlp documents, lawful presence determination and family member objects.
      # pick the event according to the changes in person or consumer role
      #
      # @param person [Person] The person object to update.
      # @param family_member [FamilyMember] The family member object to update.
      # @param active_vlp_document [VlpDocument] The active VLP document for the person.
      # @return [Dry::Monads::Result] A monad indicating success or failure with the event to publish.
      def persist(person, family_member, active_vlp_document)
        db_active_vlp_document_id = person.consumer_role.active_vlp_document_id
        person.consumer_role.active_vlp_document_id = active_vlp_document&.id if db_active_vlp_document_id != active_vlp_document&.id

        result = if person_changed?(person) && consumer_role_changed?(person.consumer_role)
                   person.skip_person_updated_event_callback = true
                   event = fetch_event_name(person)
                   person.consumer_role.save!
                   person.save!
                   { can_trigger_hub_call: true, event: event }
                 elsif person_changed?(person)
                   person.skip_person_updated_event_callback = true
                   event = fetch_event_name(person)
                   person.save!
                   { can_trigger_hub_call: true, event: event }
                 elsif consumer_role_changed?(person.consumer_role)
                   event = fetch_event_name(person)
                   person.consumer_role.save!
                   { can_trigger_hub_call: true, event: event }
                 else
                   { can_trigger_hub_call: false }
                 end

        family_member.save!
        Success(result)
      end

      def fetch_person_event_name(person)
        identifying_information_attributes = EnrollRegistry[:consumer_role_hub_call].setting(:identifying_information_attributes).item.map(&:to_sym)
        tribe_status_attributes = EnrollRegistry[:consumer_role_hub_call].setting(:indian_tribe_attributes).item.map(&:to_sym)
        valid_attributes = identifying_information_attributes + tribe_status_attributes

        event('events.person_updated', attributes: { gid: person.to_global_id.uri, payload: person.changed_attributes }) if (valid_attributes & person.changes.symbolize_keys.keys).present?
      end

      def fetch_event_name(person)
        event = fetch_person_event_name(person)
        return event if event.present?

        fetch_consumer_role_event_name(person.consumer_role)
      end

      def fetch_consumer_role_event_name(consumer_role)
        event('events.individual.consumer_roles.updated', attributes: { gid: consumer_role.to_global_id.uri, previous: {is_applying_coverage: consumer_role.is_applying_coverage} })
      end

      def person_changed?(person)
        (person.changed? && person.changes.present?) || person.addresses.any?(&:changed?) || person.emails.any?(&:changed?) || person.phones.any?(&:changed?)
      end

      def consumer_role_changed?(consumer_role)
        consumer_role.changes.present? || consumer_role.vlp_documents.any?(&:changed?) || consumer_role.lawful_presence_determination.changes.present?
      end

      def fire_update_event(event)
        event.success.publish if event.success?
      end
    end
  end
end
