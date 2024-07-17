# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Families
    # Class for creating and updating family members in cooperation with Financial Assistance engine
    class UpdateMember
      include EventSource::Command
      include Dry::Monads[:do, :result]

      # Creates or updates a family member and persists the changes to the database.
      #
      # @param params [Hash] The parameters for creating or updating the family member.
      # @option params [Hash] :member_params The parameters to create member.
      # @option params [String] :family_id The ID of the family to which the member belongs.
      # @option params [Person] :person The person object to update.
      # @return [Dry::Monads::Result] A monad indicating success or failure.
      def call(params)
        member_params, family_id, person_hbx_id = yield validate(params)
        person = yield find_person(person_hbx_id)
        member_params = yield sanitize_person_params(member_params, person)
        @member_params = member_params
        person = yield assign_member_values(person, member_params)
        active_vlp_document = yield find_active_vlp_document(person, member_params)
        family = yield find_family(family_id)
        yield build_relationship(person, family, member_params[:relationship])
        family_member = yield build_family_member(person, family)
        person_changes, consumer_role_changes = yield persist(person, family_member, active_vlp_document)
        event = yield build_event(person_changes, consumer_role_changes, person)

        fire_update_event(event) if event.present?

        Success(family_member.id)
      end

      private

      def validate(params)
        return Failure("Provide family_id to build member") if params[:family_id].blank?
        return Failure("Provide member_params to build member") if params[:member_params].blank?
        return Failure("Provide person id to build member") if params[:person_hbx_id].blank?

        Success([params[:member_params], params[:family_id].to_s, params[:person_hbx_id]])
      end

      def find_person(person_hbx_id)
        Operations::People::Find.new.call({person_hbx_id: person_hbx_id})
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
        consumer_role = person.consumer_role
        db_active_vlp_document_id = consumer_role.active_vlp_document_id
        consumer_role.active_vlp_document_id = active_vlp_document&.id if db_active_vlp_document_id != active_vlp_document&.id

        consumer_role_changes, person_changes = if person_changed?(person) && consumer_role_changed?(consumer_role)
                                                  [save_consumer_role(consumer_role), save_person(person)]
                                                elsif person_changed?(person)
                                                  [{}, save_person(person)]
                                                elsif consumer_role_changed?(consumer_role)
                                                  [save_consumer_role(consumer_role), {}]
                                                end

        family_member.save!
        Success([person_changes, consumer_role_changes])
      end

      def save_person(person)
        changes = person.changes

        # Destroys the addresses which are not present in the params
        if any_addresses_destroyed?(person)
          addresses_with_params = @member_params[:person_addresses]
          destroy_address_ids = person.addresses.inject([]) do |bson_ids, address|
            bson_ids << address.id if addresses_with_params.map { |addr| addr[:kind] }.exclude?(address.kind)
            bson_ids
          end

          person.addresses.where(:id.in => destroy_address_ids).destroy_all
        end

        person.save!
        changes
      end

      def save_consumer_role(consumer_role)
        changes = consumer_role.changes
        consumer_role.lawful_presence_determination.skip_lawful_presence_determination_callbacks = true
        consumer_role.save!
        changes
      end

      def build_person_event(person, person_changes)
        identifying_information_attributes = EnrollRegistry[:consumer_role_hub_call].setting(:identifying_information_attributes).item.map(&:to_sym)
        tribe_status_attributes = EnrollRegistry[:consumer_role_hub_call].setting(:indian_tribe_attributes).item.map(&:to_sym)
        valid_attributes = identifying_information_attributes + tribe_status_attributes

        event('events.person_updated', attributes: { gid: person.to_global_id.uri, payload: person_changes }) if (valid_attributes & person_changes.symbolize_keys.keys).present?
      end

      def build_event(person_changes, consumer_role_changes, person)
        return Success(nil) if person_changes.blank? && consumer_role_changes.blank?

        event = build_person_event(person, person_changes)
        return event if event.present?

        build_consumer_role_event(person.consumer_role)
      end

      def build_consumer_role_event(consumer_role)
        event('events.individual.consumer_roles.updated', attributes: { gid: consumer_role.to_global_id.uri, previous: {is_applying_coverage: consumer_role.is_applying_coverage} })
      end

      # Checks if any applicant addresses are destroyed for the person.
      def any_addresses_destroyed?(person)
        addresses_with_params = @member_params[:person_addresses]

        person.addresses.any? do |address|
          addresses_with_params.map { |addr| addr[:kind] }.exclude?(address.kind)
        end
      end

      def person_changed?(person)
        (person.changed? && person.changes.present?) || person.addresses.any?(&:changed?) || person.emails.any?(&:changed?) || person.phones.any?(&:changed?) || any_addresses_destroyed?(person)
      end

      def consumer_role_changed?(consumer_role)
        consumer_role.changes.present? || consumer_role.vlp_documents.any?(&:changed?) || consumer_role.lawful_presence_determination.changes.present?
      end

      def fire_update_event(event)
        Success(event.publish)
      end
    end
  end
end
